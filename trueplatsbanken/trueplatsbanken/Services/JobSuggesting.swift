import Foundation

protocol JobSuggesting {
    func fetchSuggestions(query: String, limit: Int) async throws -> [String]
}
