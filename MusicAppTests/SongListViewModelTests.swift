import XCTest
@testable import MusicApp

@MainActor
final class SongListViewModelTests: XCTestCase {

    var viewModel: SongListViewModel!
    var mockRepository: MockSongRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockSongRepository()
        viewModel = SongListViewModel(repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func waitForState(_ expectedState: SongListViewModel.State, timeout: TimeInterval = 2.0) async throws {
        let start = Date()
        while viewModel.state != expectedState {
            if Date().timeIntervalSince(start) > timeout {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Timeout waiting for state \(expectedState)"])
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
    }
    
    private func waitForNonIdleState(timeout: TimeInterval = 2.0) async throws {
        let start = Date()
        while viewModel.state == .idle || viewModel.state == .loading {
            if Date().timeIntervalSince(start) > timeout {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Timeout waiting for non-idle state"])
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
    }

    // MARK: - Test Cases

    func test_search_withValidTerm_shouldLoadSongsSuccessfully() async {
        // Given
        let searchTerm = "Lana Del Rey"
        mockRepository.mockSongs = Song.mockedDataPage1
        
        // When
        await viewModel.search(for: searchTerm)
        
        // Wait for the state to become loaded
        try? await waitForState(.loaded)
        
        // Then
        XCTAssertFalse(viewModel.songs.isEmpty, "The songs array should not be empty after a successful search.")
        XCTAssertEqual(viewModel.songs.count, 2, "The songs array should contain the 2 mocked songs.")
        XCTAssertEqual(viewModel.songs.first?.artistName, "Lana Del Rey")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after the search completes.")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil on a successful search.")
    }

    func test_search_withEmptyTerm_shouldNotPerformSearch() async {
        // Given
        let searchTerm = ""
        
        // When
        await viewModel.search(for: searchTerm)
        
        // Then
        XCTAssertTrue(viewModel.songs.isEmpty, "The songs array should remain empty when the search term is empty.")
    }

    func test_search_whenRepositoryThrowsError_shouldSetErrorMessage() async {
        // Given
        let searchTerm = "Error"
        mockRepository.mockError = APIError.requestFailed(description: "Network down")
        
        // When
        await viewModel.search(for: searchTerm)
        
        // Wait for the search task to complete
        try? await waitForNonIdleState()
        
        // Then
        XCTAssertTrue(viewModel.songs.isEmpty, "The songs array should be empty when an error occurs.")
        XCTAssertNotNil(viewModel.errorMessage, "The error message should be set.")
        XCTAssertEqual(viewModel.errorMessage, "Request failed: Network down")
    }
    
    func test_loadMoreSongs_shouldAppendNewSongs() async {
        // Given
        mockRepository.mockSongs = Song.mockedDataPage1 + Song.mockedDataPage2
        
        viewModel = SongListViewModel(resultsPerPage: 2, repository: mockRepository)
        
        // When - Initial search
        await viewModel.search(for: "test")
        
        // Wait for loaded state
        try? await waitForState(.loaded)
        
        // Then
        XCTAssertEqual(viewModel.songs.count, 2, "Initial search should only load the first page.")
        XCTAssertEqual(viewModel.state, .loaded, "State should be .loaded after successful search.")
        
        // When - Load more
        await viewModel.loadMoreSongs()
        
        // Wait for loaded state again
        try? await waitForState(.loaded)
        
        // Then
        XCTAssertEqual(viewModel.songs.count, 4, "Should append the second page of songs to the list.")
        XCTAssertEqual(viewModel.songs.last?.trackName, "West Coast")
    }
    
    func test_retry_shouldResetAndSearch() async {
        // Given
        mockRepository.mockError = APIError.requestFailed(description: "Network error")
        await viewModel.search(for: "test")
        
        // Wait for error state
        try? await waitForNonIdleState()
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When - Fix the error and retry
        mockRepository.mockError = nil
        mockRepository.mockSongs = Song.mockedDataPage1
        await viewModel.retry()
        
        // Wait for loaded state
        try? await waitForState(.loaded)
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.songs.count, 2)
    }
}

extension Song {
    static var mockedDataPage1: [Song] {
        [
            Song(
                wrapperType: "track",
                kind: "song",
                trackId: 2,
                trackName: "Video Games",
                previewUrl: URL(string: "https://example.com/preview.m4a"),
                trackTimeMillis: 282000,
                trackPrice: 1.29,
                artistName: "Lana Del Rey",
                collectionId: 123,
                collectionName: "Born to Die",
                artworkUrl100: URL(string: "https://example.com/image.jpg")!,
                primaryGenreName: "Pop",
                currency: "USD"
            ),
            Song(
                wrapperType: "track",
                kind: "song",
                trackId: 3,
                trackName: "Summertime Sadness",
                previewUrl: URL(string: "https://example.com/preview.m4a"),
                trackTimeMillis: 282000,
                trackPrice: 1.29,
                artistName: "Lana Del Rey",
                collectionId: 123,
                collectionName: "Born to Die",
                artworkUrl100: URL(string: "https://example.com/image.jpg")!,
                primaryGenreName: "Pop",
                currency: "USD"
            )
        ]
    }
    
    static var mockedDataPage2: [Song] {
        [
            Song(
                wrapperType: "track",
                kind: "song",
                trackId: 4,
                trackName: "Born to Die",
                previewUrl: URL(string: "https://example.com/preview.m4a"),
                trackTimeMillis: 282000,
                trackPrice: 1.29,
                artistName: "Lana Del Rey",
                collectionId: 123,
                collectionName: "Born to Die",
                artworkUrl100: URL(string: "https://example.com/image.jpg")!,
                primaryGenreName: "Pop",
                currency: "USD"
            ),
            Song(
                wrapperType: "track",
                kind: "song",
                trackId: 5,
                trackName: "West Coast",
                previewUrl: URL(string: "https://example.com/preview.m4a"),
                trackTimeMillis: 282000,
                trackPrice: 1.29,
                artistName: "Lana Del Rey",
                collectionId: 123,
                collectionName: "Born to Die",
                artworkUrl100: URL(string: "https://example.com/image.jpg")!,
                primaryGenreName: "Pop",
                currency: "USD"
            )
        ]
    }
}
