//
//  AudioAnalyzer.swift
//  MusicApp
//
//  Created on January 28, 2026.
//

import AVFoundation
import Accelerate

@MainActor
final class AudioAnalyzer: ObservableObject, Sendable {
    
    // MARK: - Published Properties
    @Published private(set) var magnitudes: [Float] = Array(repeating: 0.0, count: 64)
    
    @Published private(set) var isPlaying: Bool = false
    
    @Published private(set) var isLoading: Bool = false
    
    @Published private(set) var currentTime: TimeInterval = 0
    
    @Published private(set) var duration: TimeInterval = 0
    
    @Published private(set) var errorMessage: String?
    
    // MARK: - Audio Engine Components
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var displayLink: CADisplayLink?
    
    // MARK: - FFT Properties
    
    private let fftSize: Int = 2048
    private let bufferSize: AVAudioFrameCount = 2048
    private nonisolated(unsafe) var fftSetup: vDSP_DFT_Setup?
    
    let bandCount: Int = 64
    
    // MARK: - Playback State
    
    private var audioSampleRate: Double = 44100
    private var audioLengthSamples: AVAudioFramePosition = 0
    private var seekFrame: AVAudioFramePosition = 0
    private var currentFrame: AVAudioFramePosition = 0
    
    // MARK: - Thread Safety
    
    private let magnitudesLock = NSLock()
    private var pendingMagnitudes: [Float] = Array(repeating: 0.0, count: 64)
    
    // MARK: - Singleton
    
    static let shared = AudioAnalyzer()
    
    // MARK: - Initialization
    
    private init() {
        setupFFT()
    }
    
    deinit {
        if let fftSetup = fftSetup {
            vDSP_DFT_DestroySetup(fftSetup)
        }
    }
    
    // MARK: - Setup
    
    private func setupFFT() {
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            .FORWARD
        )
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }
    
    // MARK: - Public API
    func downloadAndPlay(url: URL) async {
        stop()
        
        isLoading = true
        errorMessage = nil
        
        do {
            let localURL = try await downloadAudio(from: url)
            
            try setupAudioSession()
            setupAudioEngine()
            
            try loadAudioFile(from: localURL)
            
            installTap()
            
            try startPlayback()
            
            isLoading = false
            isPlaying = true
            
            startDisplayLink()
            
        } catch {
            isLoading = false
            errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }
    
    func playPause() {
        guard let player = playerNode else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
            stopDisplayLink()
        } else {
            player.play()
            isPlaying = true
            startDisplayLink()
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = playerNode,
              let file = audioFile else { return }
        
        let wasPlaying = isPlaying
        
        player.stop()
        
        let targetFrame = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = max(0, min(targetFrame, audioLengthSamples))
        currentFrame = seekFrame
        
        let framesRemaining = audioLengthSamples - seekFrame
        guard framesRemaining > 0 else { return }
        
        player.scheduleSegment(
            file,
            startingFrame: seekFrame,
            frameCount: AVAudioFrameCount(framesRemaining),
            at: nil
        )
        
        currentTime = time
        
        if wasPlaying {
            player.play()
        }
    }
    
    func stop() {
        stopDisplayLink()
        
        playerNode?.stop()
        audioEngine?.stop()
        
        if let engine = audioEngine, let player = playerNode {
            engine.disconnectNodeOutput(player)
            engine.detach(player)
        }
        
        audioEngine = nil
        playerNode = nil
        audioFile = nil
        
        isPlaying = false
        currentTime = 0
        duration = 0
        seekFrame = 0
        currentFrame = 0
        
        magnitudes = Array(repeating: 0.0, count: bandCount)
    }
    
    // MARK: - Private Methods
    
    private func downloadAudio(from url: URL) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AudioAnalyzerError.downloadFailed
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        try data.write(to: tempURL)
        
        return tempURL
    }
    
    private func loadAudioFile(from url: URL) throws {
        audioFile = try AVAudioFile(forReading: url)
        
        guard let file = audioFile else {
            throw AudioAnalyzerError.fileLoadFailed
        }
        
        audioSampleRate = file.processingFormat.sampleRate
        audioLengthSamples = file.length
        duration = Double(audioLengthSamples) / audioSampleRate
        
        guard let player = playerNode else { return }
        
        player.scheduleFile(file, at: nil)
    }
    
    private func installTap() {
        guard let engine = audioEngine else { return }
        
        let mixerNode = engine.mainMixerNode
        let format = mixerNode.outputFormat(forBus: 0)
        
        mixerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0],
              let fftSetup = fftSetup else { return }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength >= fftSize else { return }
        
        var windowedSignal = [Float](repeating: 0, count: fftSize)
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(channelData, 1, window, 1, &windowedSignal, vDSP_Stride(1), vDSP_Length(fftSize))
        
        var realInput = windowedSignal
        var imagInput = [Float](repeating: 0, count: fftSize)
        var realOutput = [Float](repeating: 0, count: fftSize)
        var imagOutput = [Float](repeating: 0, count: fftSize)
        
        vDSP_DFT_Execute(fftSetup, &realInput, &imagInput, &realOutput, &imagOutput)
        
        var magnitudesBuffer = [Float](repeating: 0, count: fftSize / 2)
        
        realOutput.withUnsafeMutableBufferPointer { realPtr in
            imagOutput.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(
                    realp: realPtr.baseAddress!,
                    imagp: imagPtr.baseAddress!
                )
                vDSP_zvabs(&splitComplex, 1, &magnitudesBuffer, 1, vDSP_Length(fftSize / 2))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0, count: bandCount)
        let binSize = (fftSize / 2) / bandCount
        
        for i in 0..<bandCount {
            let startBin = i * binSize
            let endBin = min(startBin + binSize, fftSize / 2)
            
            var sum: Float = 0
            vDSP_sve(Array(magnitudesBuffer[startBin..<endBin]), 1, &sum, vDSP_Length(endBin - startBin))
            
            let average = sum / Float(endBin - startBin)
            
            let db = 20 * log10(max(average, 1e-6))
            let normalized = (db + 60) / 60
            normalizedMagnitudes[i] = max(0, min(1, normalized))
        }
        
        magnitudesLock.lock()
        for i in 0..<bandCount {
            pendingMagnitudes[i] = pendingMagnitudes[i] * 0.7 + normalizedMagnitudes[i] * 0.3
        }
        magnitudesLock.unlock()
    }
    
    private func startPlayback() throws {
        guard let engine = audioEngine,
              let player = playerNode else {
            throw AudioAnalyzerError.engineNotReady
        }
        
        try engine.start()
        player.play()
    }
    
    // MARK: - Display Link
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: DisplayLinkTarget { [weak self] in
            self?.updatePlaybackState()
        }, selector: #selector(DisplayLinkTarget.update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func updatePlaybackState() {
        guard let player = playerNode,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else {
            return
        }
        
        currentFrame = seekFrame + playerTime.sampleTime
        currentTime = Double(currentFrame) / audioSampleRate
        
        magnitudesLock.lock()
        magnitudes = pendingMagnitudes
        magnitudesLock.unlock()
        
        if currentFrame >= audioLengthSamples {
            isPlaying = false
            stopDisplayLink()
            currentTime = duration
        }
    }
}

// MARK: - Display Link Target

private class DisplayLinkTarget {
    private let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    @objc func update() {
        callback()
    }
}

// MARK: - Errors

enum AudioAnalyzerError: Error, LocalizedError {
    case downloadFailed
    case fileLoadFailed
    case engineNotReady
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download audio file"
        case .fileLoadFailed:
            return "Failed to load audio file"
        case .engineNotReady:
            return "Audio engine is not ready"
        }
    }
}
