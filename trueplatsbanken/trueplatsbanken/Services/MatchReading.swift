import Foundation

protocol MatchReading {
    func fetchMatches(for profile: Profile) async throws -> [MatchResult]
}
