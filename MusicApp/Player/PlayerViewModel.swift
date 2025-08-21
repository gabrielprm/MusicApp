import SwiftUI
import Combine
import Foundation

public protocol PlayerViewModelProtocol {
    func search(for term: String) async
    func loadMoreSongs() async
    func fetchAlbumSongs(for albumId: Int) async
    
    func selectSong(_ song: Song)
    func playPause()
    func skipBackward()
    func skipForward()
    func seek(to seconds: Double)
    func didTapBack()
    func didTapMenu()
}

@MainActor
final class PlayerViewModel: ObservableObject, @preconcurrency PlayerViewModelProtocol {
    
    // MARK: - Published Properties for UI
    
    @Published var songs: [Song] = []
    @Published var albumSongs: [Song] = []
    @Published var currentSong: Song?
    
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    
    @Published var showAlbumSheet = false
    @Published var showMoreOptions = false
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private var timer: AnyCancellable?
    
    private var currentPage = 1
    private var currentSearchTerm = ""
    private var canLoadMorePages = true
    private let resultsPerPage = 20
    
    // MARK: - Initializer
    
    init(repository: SongRepositoryProtocol = SongRepository()) {
        self.repository = repository
    }
    
    // MARK: - Data Fetching Methods
    
    func search(for term: String) async {
        guard !term.isEmpty else { return }
        
        currentSearchTerm = term
        songs.removeAll()
        currentPage = 1
        canLoadMorePages = true
        errorMessage = nil
        
        await loadMoreSongs()
    }
    
    func loadMoreSongs() async {
        guard !isLoading, canLoadMorePages else { return }
        
        isLoading = true
        
        do {
            let newSongs = try await repository.searchSongs(
                for: currentSearchTerm,
                page: currentPage,
                resultsPerPage: resultsPerPage
            )
            
            if newSongs.count < resultsPerPage {
                canLoadMorePages = false
            }
            
            songs.append(contentsOf: newSongs)
            currentPage += 1
            
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "An unknown error occurred."
        }
        
        isLoading = false
    }
    
    func fetchAlbumSongs(for albumId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tracks = try await repository.fetchSongs(forAlbumId: albumId)
            self.albumSongs = tracks
            self.showAlbumSheet = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load album."
        }
        
        isLoading = false
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
    
    func didTapBack() {
        print("Back tapped")
    }
    
    func didTapMenu() {
        print("Menu tapped")
    }
    
    // MARK: - Private Timer Methods
    
    private func startTicking() {
        stopTicking()
        timer = Timer.publish(every: 1.0/(currentSong?.trackDuration ?? 30.0), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isPlaying else { return }
                
                self.currentTime += 1.0/(currentSong?.trackDuration ?? 30.0)
                
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
