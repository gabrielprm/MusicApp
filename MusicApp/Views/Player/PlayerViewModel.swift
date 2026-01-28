import SwiftUI
import Combine
import Foundation
import AVFoundation

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
    
    @Published var seekValue: Double = 0
    
    let song: Song
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private var player: AVPlayer?
    private var playerItemObserver: AnyCancellable?
    private var timeObserver: Any?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerItemDidEndObserver: NSObjectProtocol?
    
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
        // Cleanup directly in deinit without calling @MainActor method
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
            // If at the end, restart from beginning
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
        showAlbumSheet = true
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
