import XCTest
@testable import MusicApp

@MainActor
final class PlayerViewModelTests: XCTestCase {

    var viewModel: PlayerViewModel!
    var mockRepository: MockSongRepository!
    var initialSong: Song!

    override func setUp() {
        super.setUp()
        initialSong = Song.mockSong
        mockRepository = MockSongRepository()
        viewModel = PlayerViewModel(song: initialSong, repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        initialSong = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func test_selectSong_updatesCurrentSongAndResetsState() {
        // Given
        let newSong = Song(
            wrapperType: "track",
            kind: "song",
            trackId: 2,
            trackName: "Video Games",
            previewUrl: nil,
            trackTimeMillis: 282000,
            trackPrice: 1.29,
            artistName: "Lana Del Rey",
            collectionId: 123,
            collectionName: "Born to Die",
            artworkUrl100: URL(string: "https://example.com/image.jpg")!,
            primaryGenreName: "Pop",
            currency: "USD"
        )
        
        // When
        viewModel.selectSong(newSong)
        
        
        // Then
        XCTAssertEqual(viewModel.currentSong?.trackId, 2)
        XCTAssertEqual(viewModel.currentTime, 0.0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.duration, newSong.trackDuration)
    }

    func test_playPause_togglesIsPlayingState() {
        // Given
        viewModel.selectSong(initialSong)
        XCTAssertFalse(viewModel.isPlaying, "Pre-condition: isPlaying should be false.")
        
        // When
        viewModel.playPause()
        
        // Then
        XCTAssertTrue(viewModel.isPlaying, "isPlaying should toggle to true.")
        
        // When
        viewModel.playPause()
        
        // Then
        XCTAssertFalse(viewModel.isPlaying, "isPlaying should toggle back to false.")
    }
    
    func test_playPause_withNoCurrentSong_doesNothing() {
        // Given
        XCTAssertNil(viewModel.currentSong)
        
        // When
        viewModel.playPause()
        
        // Then
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    func test_skipForward_advancesTimeAndClampsToDuration() {
        // Given
        viewModel.selectSong(initialSong)
        viewModel.currentTime = 55.0
        
        // When
        viewModel.skipForward()
        
        // Then
        XCTAssertEqual(viewModel.currentTime, 60.0, "Time should be clamped at the song's duration.")
    }
    
    func test_skipBackward_rewindsTimeAndClampsToZero() {
        // Given
        viewModel.selectSong(initialSong)
        viewModel.currentTime = 5.0
        
        // When
        viewModel.skipBackward()
        
        // Then
        XCTAssertEqual(viewModel.currentTime, 0.0, "Time should be clamped at zero.")
    }
    
    func test_seek_updatesCurrentTimeWithinBounds() {
        // Given
        viewModel.selectSong(initialSong)
        
        // When
        viewModel.seek(to: 35.0)
        
        // Then
        XCTAssertEqual(viewModel.currentTime, 35.0)
        
        // When
        viewModel.seek(to: 100.0)
        
        // Then
        XCTAssertEqual(viewModel.currentTime, 60.0)
    }
}
