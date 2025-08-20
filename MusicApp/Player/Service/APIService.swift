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

class APIService: APIServiceProtocol {
    private let baseURL = "https://itunes.apple.com/search"

    func search(term: String, limit: Int, offset: Int) async throws -> SearchResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }

            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            return searchResponse

        } catch let error as DecodingError {
            throw APIError.decodingError(description: error.localizedDescription)
        } catch {
            throw APIError.requestFailed(description: error.localizedDescription)
        }
    }
    
    func fetchSongs(forAlbumId albumId: Int) async throws -> SearchResponse {
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "id", value: String(albumId)),
                URLQueryItem(name: "entity", value: "song")
            ]

            guard let url = components?.url else {
                throw APIError.invalidURL
            }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw APIError.invalidResponse
                }

                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(SearchResponse.self, from: data)
                return searchResponse

            } catch let error as DecodingError {
                throw APIError.decodingError(description: error.localizedDescription)
            } catch {
                throw APIError.requestFailed(description: error.localizedDescription)
            }
        }
}
