import XCTest
@testable import MusicApp // Replace with your project name

@MainActor
final class AlbumSongsViewModelTests: XCTestCase {

    var viewModel: AlbumSongsViewModel!
    var mockRepository: MockSongRepository!
    let testAlbumId = 101

    override func setUp() {
        super.setUp()
        mockRepository = MockSongRepository()
        viewModel = AlbumSongsViewModel(albumId: testAlbumId, repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func test_fetchAlbumSongs_whenSuccessful_shouldLoadSongsForCorrectAlbum() async {
        // Given
        mockRepository.mockSongs = Song.mockedAlbumData
        
        // When
        await viewModel.fetchAlbumSongs()
        
        // Then
        XCTAssertFalse(viewModel.albumSongs.isEmpty)
        XCTAssertEqual(viewModel.albumSongs.count, 2)
        XCTAssertEqual(viewModel.albumSongs.first?.collectionId, testAlbumId)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_fetchAlbumSongs_whenRepositoryThrowsError_shouldSetErrorMessage() async {
        // Given
        mockRepository.mockError = APIError.invalidResponse
        
        // When
        await viewModel.fetchAlbumSongs()
        
        // Then
        XCTAssertTrue(viewModel.albumSongs.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Received an invalid response from the server.")
    }
    
    func test_isLoading_isSetCorrectlyDuringFetch() async {
        // Given
        let expectation = XCTestExpectation(description: "isLoading was checked mid-fetch")
        mockRepository.mockSongs = Song.mockedAlbumData
        
        mockRepository.onFetchSongs = {
            XCTAssertTrue(self.viewModel.isLoading, "isLoading should be true during the fetch.")
            expectation.fulfill()
        }

        // When
        await viewModel.fetchAlbumSongs()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after the fetch completes.")
    }
}
