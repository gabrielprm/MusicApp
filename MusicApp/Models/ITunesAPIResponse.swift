import Foundation

struct SearchResponse: Codable {
    let resultCount: Int
    let results: [Song]
}

struct Song: Codable, Identifiable, Hashable {
    let trackId: Int
    let artistName: String
    let collectionName: String?
    let trackName: String
    let previewUrl: URL
    let artworkUrl100: URL
    
    let primaryGenreName: String
    let trackPrice: Double?
    let currency: String
    let trackExplicitness: String
    let trackTimeMillis: Int
    
    
    var id: Int {
        return trackId
    }
    
    var artworkUrlLarge: URL? {
        let largeURLString = artworkUrl100.absoluteString
            .replacingOccurrences(of: "100x100", with: "600x600")
        return URL(string: largeURLString)
    }
    
    var trackDuration: Double {
        Double(trackTimeMillis / 1000)
    }
}
