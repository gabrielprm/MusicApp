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
    
    enum SearchMode: String, CaseIterable {
        case keyword = "Keyword"
        case semantic = "Semantic"
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var state: State = .idle
    @Published private(set) var songs: [Song] = []
    @Published var searchText: String = ""
    @Published var searchMode: SearchMode = .semantic
    
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
    
    var isSemanticSearchAvailable: Bool {
        semanticSearchService.isAvailable
    }
    
    // MARK: - Private Properties
    
    private let repository: SongRepositoryProtocol
    private let semanticSearchService: SemanticSearchService
    private let resultsPerPage: Int
    
    private var currentPage = 1
    private var currentSearchTerm = ""
    private var canLoadMorePages = true
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var allFetchedSongs: [Song] = [] // Store all fetched songs for semantic re-ranking
    
    // MARK: - Initializer
    
    init(
        resultsPerPage: Int = 20,
        repository: SongRepositoryProtocol = SongRepository(),
        semanticSearchService: SemanticSearchService = .shared
    ) {
        self.resultsPerPage = resultsPerPage
        self.repository = repository
        self.semanticSearchService = semanticSearchService
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
            allFetchedSongs.removeAll()
            semanticSearchService.clearIndex()
            state = .idle
            return
        }
        
        currentSearchTerm = term
        songs.removeAll()
        allFetchedSongs.removeAll()
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
            
            allFetchedSongs.append(contentsOf: newSongs)
            currentPage += 1
            
            if searchMode == .semantic && semanticSearchService.isAvailable {
                await applySemanticRanking()
            } else {
                songs = allFetchedSongs
            }
            
            state = .loaded
            
        } catch {
            guard !Task.isCancelled else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? "An unknown error occurred."
            state = .error(message)
        }
    }
    
    private func applySemanticRanking() async {
        semanticSearchService.indexSongs(allFetchedSongs)
        
        let rankedSongs = semanticSearchService.search(
            query: currentSearchTerm,
            limit: allFetchedSongs.count
        )
        
        songs = rankedSongs.isEmpty ? allFetchedSongs : rankedSongs
    }
    
    func toggleSearchMode() async {
        searchMode = searchMode == .keyword ? .semantic : .keyword
        
        guard !allFetchedSongs.isEmpty else { return }
        
        if searchMode == .semantic && semanticSearchService.isAvailable {
            await applySemanticRanking()
        } else {
            songs = allFetchedSongs
        }
    }
    
    func retry() async {
        state = .idle
        await search(for: currentSearchTerm)
    }
}
