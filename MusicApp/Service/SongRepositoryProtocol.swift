import Foundation

protocol SongRepositoryProtocol {
    func searchSongs(for term: String, page: Int, resultsPerPage: Int) async throws -> [Song]
    func fetchSongs(forAlbumId albumId: Int) async throws -> [Song]
}

class SongRepository: SongRepositoryProtocol {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    func searchSongs(for term: String, page: Int, resultsPerPage: Int) async throws -> [Song] {
        guard page > 0, resultsPerPage > 0 else {
            return []
        }

        let offset = (page - 1) * resultsPerPage
        
        let response = try await apiService.search(term: term, limit: resultsPerPage, offset: offset)
        return response.results
    }
    
    func fetchSongs(forAlbumId albumId: Int) async throws -> [Song] {
        let response = try await apiService.fetchSongs(forAlbumId: albumId)
        
        let songs = response.results.filter { $0.wrapperType == "track" }
        return songs
    }
}
