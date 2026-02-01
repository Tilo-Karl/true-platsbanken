import Foundation

protocol MatchReading {
    func fetchMatches(for payload: ProfileMatchPayload, profileEmbedding: [Double]?) async throws -> [MatchResult]
}
