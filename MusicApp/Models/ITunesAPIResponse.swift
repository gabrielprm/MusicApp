import Foundation

public struct SearchResponse: Codable {
    let resultCount: Int
    let results: [Song]
}

public struct Song: Codable, Identifiable, Hashable {
    let wrapperType: String?
    let kind: String?

    let trackId: Int?
    let trackName: String?
    let previewUrl: URL?
    let trackTimeMillis: Int?
    let trackPrice: Double?

    let artistName: String
    let collectionId: Int
    let collectionName: String?
    let artworkUrl100: URL
    let primaryGenreName: String
    let currency: String
    
    public var id: String {
        if let trackId = self.trackId {
            return "track-\(trackId)"
        } else {
            return "collection-\(self.collectionId)"
        }
    }

    var artworkUrlLarge: URL? {
        let largeURLString = artworkUrl100.absoluteString
            .replacingOccurrences(of: "100x100", with: "600x600")
        return URL(string: largeURLString)
    }
    
    var trackDuration: Double {
        Double((trackTimeMillis ?? 0) / 1000)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}
