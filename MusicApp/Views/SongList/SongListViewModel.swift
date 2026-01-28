import Foundation
import Combine

@MainActor
final class SongListViewModel: ObservableObject {
    
    // MARK: - State
    
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case loadingMore
        case error(String)
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var state: State = .idle
    @Published private(set) var songs: [Song] = []
    @Published var searchText: String = ""
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        state == .loading
    }
    
    var isLoadingMore: Bool {
        state == .loadingMore
    }
    
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
    
    var showEmptyState: Bool {
        state == .idle && songs.isEmpty
    }
    
    var showNoResults: Bool {
        state == .loaded && songs.isEmpty
    }
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private let resultsPerPage: Int
    
    private var currentPage = 1
    private var currentSearchTerm = ""
    private var canLoadMorePages = true
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        resultsPerPage: Int = 20,
        repository: SongRepositoryProtocol = SongRepository()
    ) {
        self.resultsPerPage = resultsPerPage
        self.repository = repository
        setupSearchDebounce()
    }
    
    // MARK: - Search Debouncing
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] term in
                guard let self = self else { return }
                Task {
                    await self.search(for: term)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Fetching Methods
    
    func search(for term: String) async {
        searchTask?.cancel()
        
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            songs.removeAll()
            state = .idle
            return
        }
        
        currentSearchTerm = term
        songs.removeAll()
        currentPage = 1
        canLoadMorePages = true
        state = .loading
        
        searchTask = Task {
            await performSearch()
        }
    }
    
    func loadMoreSongs() async {
        guard state == .loaded, canLoadMorePages else { return }
        
        state = .loadingMore
        await performSearch()
    }
    
    private func performSearch() async {
        do {
            let newSongs = try await repository.searchSongs(
                for: currentSearchTerm,
                page: currentPage,
                resultsPerPage: resultsPerPage
            )
            
            guard !Task.isCancelled else { return }
            
            if newSongs.count < resultsPerPage {
                canLoadMorePages = false
            }
            
            songs.append(contentsOf: newSongs)
            currentPage += 1
            state = .loaded
            
        } catch {
            guard !Task.isCancelled else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? "An unknown error occurred."
            state = .error(message)
        }
    }
    
    func retry() async {
        state = .idle
        await search(for: currentSearchTerm)
    }
}
