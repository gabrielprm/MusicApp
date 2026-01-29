import SwiftUI
import Combine
import Foundation
import AVFoundation
@preconcurrency import ObjectiveC

public protocol PlayerViewModelProtocol {
    func selectSong(_ song: Song)
    func playPause()
    func skipBackward()
    func skipForward()
    func seek(to seconds: Double)
}

@MainActor
final class PlayerViewModel: ObservableObject, @preconcurrency PlayerViewModelProtocol {
    
    // MARK: - Published Properties for UI
    
    @Published var currentSong: Song?
    
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    
    @Published var showMoreOptions = false
    @Published var showAlbumSheet = false
    @Published var pendingAlbumSheet = false
    @Published var showSimilarSongs = false
    @Published var pendingSimilarSongs = false
    @Published var similarSongs: [Song] = []
    @Published var isLoadingSimilarSongs = false
    
    @Published var seekValue: Double = 0
    
    // MARK: - Visualizer Properties
    
    @Published var showVisualizer = false
    @Published var pendingVisualizer = false
    @Published var visualizerStyle: VisualizerStyle = .bars
    @Published var magnitudes: [Float] = Array(repeating: 0.0, count: 64)
    @Published var isVisualizerMode: Bool = false
    
    let song: Song
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private let audioAnalyzer = AudioAnalyzer.shared
    private var analyzerCancellables = Set<AnyCancellable>()
    
    private nonisolated(unsafe) var player: AVPlayer?
    private var playerItemObserver: AnyCancellable?
    private nonisolated(unsafe) var timeObserver: Any?
    private nonisolated(unsafe) var playerItemStatusObserver: NSKeyValueObservation?
    private nonisolated(unsafe) var playerItemDidEndObserver: NSObjectProtocol?
    
    // MARK: - Initializer
    
    init(
        song: Song,
        repository: SongRepositoryProtocol = SongRepository()
    ) {
        self.song = song
        self.repository = repository
        setupAudioSession()
    }
    
    deinit {
        player?.pause()
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        playerItemStatusObserver?.invalidate()
        if let observer = playerItemDidEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Player Control Methods
    func selectSong(_ song: Song) {
        currentSong = song
        currentTime = 0
        isPlaying = false
        duration = song.trackDuration
        
        // Setup player with preview URL
        guard let previewUrl = song.previewUrl else {
            errorMessage = "No preview available for this song"
            return
        }
        
        setupPlayer(with: previewUrl)
    }
    
    private func setupPlayer(with url: URL) {
        cleanupPlayer()
        isLoading = true
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player item status
        playerItemStatusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.handlePlayerItemStatus(item.status)
            }
        }
        
        // Observe when playback ends
        playerItemDidEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePlaybackEnded()
            }
        }
        
        // Add periodic time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self, self.isPlaying else { return }
                let seconds = CMTimeGetSeconds(time)
                if seconds.isFinite && !seconds.isNaN {
                    self.currentTime = seconds
                }
            }
        }
    }
    
    private func handlePlayerItemStatus(_ status: AVPlayerItem.Status) {
        isLoading = false
        
        switch status {
        case .readyToPlay:
            if let currentItem = player?.currentItem {
                let itemDuration = CMTimeGetSeconds(currentItem.duration)
                if itemDuration.isFinite && !itemDuration.isNaN {
                    duration = itemDuration
                }
            }
            errorMessage = nil
        case .failed:
            errorMessage = player?.currentItem?.error?.localizedDescription ?? "Failed to load audio"
            isPlaying = false
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handlePlaybackEnded() {
        isPlaying = false
        currentTime = duration
    }
    
    func playPause() {
        guard currentSong != nil, player != nil else { return }
        
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            if currentTime >= duration - 0.1 {
                seek(to: 0)
            }
            player?.play()
            isPlaying = true
        }
    }
    
    func skipBackward() {
        seek(to: max(0, currentTime - 10))
    }
    
    func skipForward() {
        seek(to: min(duration, currentTime + 10))
    }
    
    func seek(to seconds: Double) {
        let clampedSeconds = min(max(0, seconds), duration)
        currentTime = clampedSeconds
        
        let time = CMTime(seconds: clampedSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
        
    func presentAlbumSheet() {
        pendingAlbumSheet = true
        showMoreOptions = false
    }
    
    func presentSimilarSongs() {
        pendingSimilarSongs = true
        showMoreOptions = false
    }
    
    func presentVisualizer() {
        pendingVisualizer = true
        showMoreOptions = false
    }
    
    func onMoreOptionsDismissed() {
        if pendingAlbumSheet {
            pendingAlbumSheet = false
            showAlbumSheet = true
        } else if pendingSimilarSongs {
            pendingSimilarSongs = false
            showSimilarSongs = true
            Task {
                await loadSimilarSongs()
            }
        } else if pendingVisualizer {
            pendingVisualizer = false
            showVisualizer = true
            Task {
                await startVisualizerMode()
            }
        }
    }
    
    // MARK: - Visualizer Mode
    
    func startVisualizerMode() async {
        guard let song = currentSong,
              let previewUrl = song.previewUrl else {
            errorMessage = "No preview available for visualizer"
            return
        }
        
        // Stop current player
        cleanupPlayer()
        isVisualizerMode = true
        
        // Bind to AudioAnalyzer
        bindToAudioAnalyzer()
        
        // Start the audio analyzer
        await audioAnalyzer.downloadAndPlay(url: previewUrl)
    }
    
    func stopVisualizerMode() {
        audioAnalyzer.stop()
        analyzerCancellables.removeAll()
        isVisualizerMode = false
        magnitudes = Array(repeating: 0.0, count: 64)
        
        // Restart regular player if song is selected
        if let song = currentSong, let url = song.previewUrl {
            setupPlayer(with: url)
        }
    }
    
    private func bindToAudioAnalyzer() {
        analyzerCancellables.removeAll()
        
        audioAnalyzer.$magnitudes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newMagnitudes: [Float]) in
                self?.magnitudes = newMagnitudes
            }
            .store(in: &analyzerCancellables)
        
        audioAnalyzer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                self?.isPlaying = playing
            }
            .store(in: &analyzerCancellables)
        
        audioAnalyzer.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &analyzerCancellables)
        
        audioAnalyzer.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &analyzerCancellables)
        
        audioAnalyzer.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dur in
                self?.duration = dur
            }
            .store(in: &analyzerCancellables)
        
        audioAnalyzer.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &analyzerCancellables)
    }
    
    func visualizerPlayPause() {
        audioAnalyzer.playPause()
    }
    
    func visualizerSeek(to time: Double) {
        audioAnalyzer.seek(to: time)
    }
    
    // MARK: - Similar Songs
    
    func loadSimilarSongs() async {
        guard let currentSong = currentSong else { return }
        
        isLoadingSimilarSongs = true
        
        do {
            let repository = SongRepository()
            var allSongs: [Song] = []
            
            let artistSongs = try await repository.searchSongs(
                for: currentSong.artistName,
                page: 1,
                resultsPerPage: 25
            )
            allSongs.append(contentsOf: artistSongs)
            
            let genreSongs = try await repository.searchSongs(
                for: currentSong.primaryGenreName,
                page: 1,
                resultsPerPage: 25
            )
            allSongs.append(contentsOf: genreSongs)
            
            let uniqueSongs = Array(Set(allSongs)).filter { $0.id != currentSong.id }
            
            let semanticService = SemanticSearchService.shared
            semanticService.clearIndex()
            semanticService.indexSongs(uniqueSongs)
            
            let query = "\(currentSong.trackName ?? "") \(currentSong.artistName) \(currentSong.primaryGenreName)"
            similarSongs = semanticService.search(query: query, limit: 15)
            
            if similarSongs.isEmpty {
                similarSongs = Array(uniqueSongs.prefix(15))
            }
            
        } catch {
            similarSongs = []
        }
        
        isLoadingSimilarSongs = false
    }
    
    // MARK: - Cleanup
    
    private func cleanupPlayer() {
        player?.pause()
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        playerItemStatusObserver?.invalidate()
        playerItemStatusObserver = nil
        
        if let observer = playerItemDidEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemDidEndObserver = nil
        }
        
        player = nil
    }
}
