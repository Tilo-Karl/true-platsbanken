import Foundation

protocol MatchReading {
    func fetchMatches(for payload: ProfileMatchPayload) async throws -> [MatchResult]
}
