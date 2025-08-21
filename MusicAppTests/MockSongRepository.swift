import Foundation
@testable import MusicApp

class MockSongRepository: SongRepositoryProtocol {
    var mockSongs: [Song] = []
    var mockError: Error?

    var onFetchSongs: (() -> Void)?
    func searchSongs(for term: String, page: Int, resultsPerPage: Int) async throws -> [Song] {
        if let error = mockError {
            throw error
        }

        let startIndex = (page - 1) * resultsPerPage
        
        guard startIndex < mockSongs.count else {
            return []
        }
        
        let endIndex = min(startIndex + resultsPerPage, mockSongs.count)
        
        return Array(mockSongs[startIndex..<endIndex])
    }

    func fetchSongs(forAlbumId albumId: Int) async throws -> [Song] {
        onFetchSongs?()
        
        if let error = mockError {
            throw error
        }
        return mockSongs.filter { $0.collectionId == albumId }
    }
}

extension Song {
    static var mockSong: Song {
        Song(
            wrapperType: "track",
            kind: "song",
            trackId: 123,
            trackName: "Test Track",
            previewUrl: nil,
            trackTimeMillis: 60000,
            trackPrice: 1.29,
            artistName: "Test Artist",
            collectionId: 456,
            collectionName: "Test Album",
            artworkUrl100: URL(string: "https://example.com/art.jpg")!,
            primaryGenreName: "Test Genre",
            currency: "USD"
        )
    }
    
    static var mockedAlbumData: [Song] {
        let albumId = 101        
        return [
            Song(
                wrapperType: "track",
                kind: "song",
                trackId: 1,
                trackName: "Summertime Sadness",
                previewUrl: nil,
                trackTimeMillis: 240000,
                trackPrice: 1.29,
                artistName: "Lana Del Rey",
                collectionId: albumId,
                collectionName: "Born to Die",
                artworkUrl100: URL(string: "https://example.com/image.jpg")!,
                primaryGenreName: "Pop",
                currency: "USD"
            ),
            Song(
                wrapperType: "track",
                kind: "song",
                trackId: 2,
                trackName: "Video Games",
                previewUrl: nil,
                trackTimeMillis: 282000,
                trackPrice: 1.29,
                artistName: "Lana Del Rey",
                collectionId: albumId,
                collectionName: "Born to Die",
                artworkUrl100: URL(string: "https://example.com/image.jpg")!,
                primaryGenreName: "Pop",
                currency: "USD"
            )
        ]
    }
}
