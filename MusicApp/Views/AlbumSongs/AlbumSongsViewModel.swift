import Foundation

@MainActor
final class AlbumSongsViewModel: ObservableObject {
    
    // MARK: - State
    
    enum State: Equatable {
        case idle
        case loading
        case loaded([Song])
        case error(String)
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var state: State = .idle
    
    // MARK: - Computed Properties
    
    var albumSongs: [Song] {
        if case .loaded(let songs) = state {
            return songs
        }
        return []
    }
    
    var albumName: String {
        albumSongs.first?.collectionName ?? "Album"
    }
    
    var isLoading: Bool {
        state == .loading
    }
    
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
    
    var hasError: Bool {
        if case .error = state {
            return true
        }
        return false
    }
    
    var isEmpty: Bool {
        if case .loaded(let songs) = state {
            return songs.isEmpty
        }
        return false
    }
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private let albumId: Int
    private var hasFetched = false
    
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
        guard !hasFetched, state != .loading else { return }
        
        hasFetched = true
        state = .loading
        
        do {
            let tracks = try await repository.fetchSongs(forAlbumId: albumId)
            state = .loaded(tracks)
        } catch {
            hasFetched = false
            let message = (error as? LocalizedError)?.errorDescription ?? "Failed to load album."
            state = .error(message)
        }
    }
    
    func retry() async {
        hasFetched = false
        state = .idle
        await fetchAlbumSongs()
    }
}
