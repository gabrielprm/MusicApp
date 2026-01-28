import Foundation
import NaturalLanguage

/// Service for performing semantic vector search on songs using NLEmbedding
final class SemanticSearchService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = SemanticSearchService()
    
    // MARK: - Properties
    
    private let embedding: NLEmbedding?
    private var songVectors: [String: (song: Song, vector: [Double])] = [:]
    private let lock = NSLock()
    
    // MARK: - Initializer
    
    private init() {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    // MARK: - Public Methods
    
    var isAvailable: Bool {
        embedding != nil
    }
    
    /// Index songs for semantic search by creating embeddings
    /// - Parameter songs: Array of songs to index
    func indexSongs(_ songs: [Song]) {
        guard let embedding = embedding else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        for song in songs {
            let searchableText = createSearchableText(for: song)
            
            if let vector = embedding.vector(for: searchableText) {
                songVectors[song.id] = (song: song, vector: vector)
            }
        }
    }
    
    func clearIndex() {
        lock.lock()
        defer { lock.unlock() }
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
        
        lock.lock()
        let currentVectors = songVectors
        lock.unlock()
        
        var scoredSongs: [(song: Song, similarity: Double)] = []
        
        for (_, value) in currentVectors {
            let similarity = cosineSimilarity(queryVector, value.vector)
            scoredSongs.append((song: value.song, similarity: similarity))
        }
        
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
        
        lock.lock()
        let currentVectors = songVectors
        lock.unlock()
        
        var scoredSongs: [(song: Song, score: Double)] = []
        
        for (_, value) in currentVectors {
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
        lock.lock()
        let currentVectors = songVectors
        lock.unlock()
        
        guard let songData = currentVectors[song.id] else {
            return []
        }
        
        var scoredSongs: [(song: Song, similarity: Double)] = []
        
        for (id, value) in currentVectors where id != song.id {
            let similarity = cosineSimilarity(songData.vector, value.vector)
            scoredSongs.append((song: value.song, similarity: similarity))
        }
        
        return scoredSongs
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0.song }
    }
    
    // MARK: - Private Methods
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
