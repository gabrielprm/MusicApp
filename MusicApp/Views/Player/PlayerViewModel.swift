import SwiftUI
import Combine
import Foundation

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
    private var timer: AnyCancellable?
    
    // MARK: - Initializer
    
    init(
        song: Song,
        repository: SongRepositoryProtocol = SongRepository()
    ) {
        self.song = song
        self.repository = repository
    }
    
    // MARK: - Player Control Methods
    func selectSong(_ song: Song) {
        currentSong = song
        currentTime = 0
        isPlaying = false
        stopTicking()
        duration = song.trackDuration
    }
    
    func playPause() {
        guard currentSong != nil else { return }
        
        isPlaying.toggle()
        if isPlaying {
            startTicking()
        } else {
            stopTicking()
        }
    }
    
    func skipBackward() {
        seek(to: max(0, currentTime - 10))
    }
    
    func skipForward() {
        seek(to: min(duration, currentTime + 10))
    }
    
    func seek(to seconds: Double) {
        currentTime = min(max(0, seconds), duration)
    }
        
    func presentAlbumSheet() {
        showAlbumSheet = true
    }
    // MARK: - Private Timer Methods
    
    private func startTicking() {
        stopTicking()
        timer = Timer.publish(every: (1.0 / duration), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isPlaying else { return }
                
                self.currentTime += 1.0 / duration
                
                if self.currentTime >= self.duration {
                    self.currentTime = self.duration
                    self.playPause()
                }
            }
    }
    
    private func stopTicking() {
        timer?.cancel()
        timer = nil
    }
}
