import SwiftUI
import Combine
import Foundation

@MainActor
final class AlbumSongsViewModel: ObservableObject {
    
    // MARK: - Published Properties for UI
    
    @Published var albumSongs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private let albumId: Int
    
    // MARK: - Initializer
    
    init(
        albumId: Int,
        repository: SongRepositoryProtocol = SongRepository()
    ) {
        self.albumId = albumId
        self.repository = repository
    }
    
    // MARK: - Data Fetching Methods
    
    func fetchAlbumSongs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tracks = try await repository.fetchSongs(forAlbumId: albumId)
            self.albumSongs = tracks
            
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load album."
        }
        
        isLoading = false
    }
}
