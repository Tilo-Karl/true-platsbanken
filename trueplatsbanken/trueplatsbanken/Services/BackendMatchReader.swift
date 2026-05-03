import Foundation

final class BackendMatchReader: MatchReading {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL ?? BackendServiceURLProvider.baseURL()
        self.session = session
    }

    func fetchMatches(for payload: ProfileMatchPayload, profileEmbedding: [Double]?) async throws -> [MatchResult] {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("match")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = MatchRequest(profile: payload, limit: 30, profileEmbedding: profileEmbedding)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(MatchResponse.self, from: data)
        let rawMatches: [MatchPayload]
        if let core = payload.coreMatches, let pivot = payload.pivotMatches {
            rawMatches = core + pivot
        } else {
            rawMatches = payload.matches
        }

        return rawMatches.map { match in
            MatchResult(
                id: match.jobId,
                job: match.job,
                score: match.score,
                reasons: match.reasons,
                matchType: match.matchType ?? .core
            )
        }
    }

}

private struct MatchRequest: Encodable {
    let profile: ProfileMatchPayload
    let limit: Int
    let profileEmbedding: [Double]?
}

private struct MatchResponse: Decodable {
    let matches: [MatchPayload]
    let coreMatches: [MatchPayload]?
    let pivotMatches: [MatchPayload]?
}

private struct MatchPayload: Decodable {
    let jobId: String
    let job: Job
    let score: Double?
    let reasons: [String]
    let matchType: MatchResult.MatchType?
}
