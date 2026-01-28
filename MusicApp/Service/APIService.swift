import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(description: String)
    case invalidResponse
    case decodingError(description: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .requestFailed(let description):
            return "Request failed: \(description)"
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingError(let description):
            return "Failed to decode the response: \(description)"
        }
    }
}

protocol APIServiceProtocol {
    func search(term: String, limit: Int, offset: Int) async throws -> SearchResponse
    func fetchSongs(forAlbumId albumId: Int) async throws -> SearchResponse
}

final class APIService: APIServiceProtocol {
    
    // MARK: - Constants
    
    private enum Endpoint {
        static let search = "https://itunes.apple.com/search"
        static let lookup = "https://itunes.apple.com/lookup"
    }
    
    // MARK: - Dependencies
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Initializer
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Public Methods
    
    func search(term: String, limit: Int, offset: Int) async throws -> SearchResponse {
        var components = URLComponents(string: Endpoint.search)
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        return try await fetch(from: components)
    }
    
    func fetchSongs(forAlbumId albumId: Int) async throws -> SearchResponse {
        var components = URLComponents(string: Endpoint.lookup)
        components?.queryItems = [
            URLQueryItem(name: "id", value: String(albumId)),
            URLQueryItem(name: "entity", value: "song")
        ]
        
        return try await fetch(from: components)
    }
    
    // MARK: - Private Methods
    
    private func fetch<T: Decodable>(from components: URLComponents?) async throws -> T {
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw APIError.decodingError(description: error.localizedDescription)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(description: error.localizedDescription)
        }
    }
}
