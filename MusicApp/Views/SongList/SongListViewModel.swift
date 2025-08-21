import SwiftUI
import Combine
import Foundation

@MainActor
final class SongListViewModel: ObservableObject {
    
    // MARK: - Published Properties for UI
    
    @Published var songs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    
    private var currentPage = 1
    private var currentSearchTerm = ""
    private var canLoadMorePages = true
    private let resultsPerPage: Int
    
    // MARK: - Initializer
    
    init(
        resultsPerPage: Int = 20,
        repository: SongRepositoryProtocol = SongRepository()
    ) {
        self.resultsPerPage = resultsPerPage
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
}
