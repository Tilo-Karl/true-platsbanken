import Foundation

final class DemoMatchReader: MatchReading {
    func fetchMatches(for payload: ProfileMatchPayload, profileEmbedding: [Double]?) async throws -> [MatchResult] {
        return try DemoMatchSnapshot.load()
    }
}
