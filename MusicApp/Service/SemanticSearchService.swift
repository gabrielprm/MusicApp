import Foundation
import NaturalLanguage

/// Service for performing semantic vector search on songs using NLEmbedding
final class SemanticSearchService {
    
    // MARK: - Singleton
    
    static let shared = SemanticSearchService()
    
    // MARK: - Properties
    
    private let embedding: NLEmbedding?
    private var songVectors: [String: (song: Song, vector: [Double])] = [:]
    
    // MARK: - Initializer
    
    private init() {
        // Use sentence embedding for better semantic understanding
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    // MARK: - Public Methods
    
    /// Check if semantic search is available
    var isAvailable: Bool {
        embedding != nil
    }
    
    /// Index songs for semantic search by creating embeddings
    /// - Parameter songs: Array of songs to index
    func indexSongs(_ songs: [Song]) {
        guard let embedding = embedding else { return }
        
        for song in songs {
            let searchableText = createSearchableText(for: song)
            
            if let vector = embedding.vector(for: searchableText) {
                songVectors[song.id] = (song: song, vector: vector)
            }
        }
    }
    
    /// Remove songs from the index
    func clearIndex() {
        songVectors.removeAll()
    }
    
    /// Perform semantic search on indexed songs
    /// - Parameters:
    ///   - query: The search query (e.g., "sad girl winter", "upbeat dance music")
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of songs sorted by semantic similarity
    func search(query: String, limit: Int = 20) -> [Song] {
        guard let embedding = embedding,
              let queryVector = embedding.vector(for: query) else {
            return []
        }
        
        // Calculate cosine similarity for each indexed song
        var scoredSongs: [(song: Song, similarity: Double)] = []
        
        for (_, value) in songVectors {
            let similarity = cosineSimilarity(queryVector, value.vector)
            scoredSongs.append((song: value.song, similarity: similarity))
        }
        
        // Sort by similarity (highest first) and return top results
        let sortedSongs = scoredSongs
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0.song }
        
        return Array(sortedSongs)
    }
    
    /// Perform semantic search with similarity scores
    /// - Parameters:
    ///   - query: The search query
    ///   - limit: Maximum number of results
    /// - Returns: Array of tuples containing songs and their similarity scores
    func searchWithScores(query: String, limit: Int = 20) -> [(song: Song, score: Double)] {
        guard let embedding = embedding,
              let queryVector = embedding.vector(for: query) else {
            return []
        }
        
        var scoredSongs: [(song: Song, score: Double)] = []
        
        for (_, value) in songVectors {
            let similarity = cosineSimilarity(queryVector, value.vector)
            scoredSongs.append((song: value.song, score: similarity))
        }
        
        return scoredSongs
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Find songs similar to a given song
    /// - Parameters:
    ///   - song: The reference song
    ///   - limit: Maximum number of similar songs to return
    /// - Returns: Array of similar songs
    func findSimilarSongs(to song: Song, limit: Int = 10) -> [Song] {
        guard let songData = songVectors[song.id] else {
            return []
        }
        
        var scoredSongs: [(song: Song, similarity: Double)] = []
        
        for (id, value) in songVectors where id != song.id {
            let similarity = cosineSimilarity(songData.vector, value.vector)
            scoredSongs.append((song: value.song, similarity: similarity))
        }
        
        return scoredSongs
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0.song }
    }
    
    // MARK: - Private Methods
    
    /// Create searchable text from song metadata
    private func createSearchableText(for song: Song) -> String {
        var components: [String] = []
        
        if let trackName = song.trackName {
            components.append(trackName)
        }
        
        components.append(song.artistName)
        
        if let collectionName = song.collectionName {
            components.append(collectionName)
        }
        
        components.append(song.primaryGenreName)
        
        return components.joined(separator: " ")
    }
    
    /// Calculate cosine similarity between two vectors
    /// - Returns: Similarity score between -1 and 1 (1 = identical, 0 = orthogonal, -1 = opposite)
    private func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        guard vectorA.count == vectorB.count, !vectorA.isEmpty else {
            return 0
        }
        
        var dotProduct: Double = 0
        var magnitudeA: Double = 0
        var magnitudeB: Double = 0
        
        for i in 0..<vectorA.count {
            dotProduct += vectorA[i] * vectorB[i]
            magnitudeA += vectorA[i] * vectorA[i]
            magnitudeB += vectorB[i] * vectorB[i]
        }
        
        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        
        guard magnitude > 0 else { return 0 }
        
        return dotProduct / magnitude
    }
}
