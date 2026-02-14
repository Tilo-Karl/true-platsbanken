import Foundation

final class BackendJobSuggester: JobSuggesting {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL ?? BackendServiceURLProvider.baseURL()
        self.session = session
    }

    func fetchSuggestions(query: String, limit: Int) async throws -> [String] {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("suggest")
        url.append(queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ])

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let payload = try decoder.decode(JobSuggestResponseDTO.self, from: data)
        return payload.suggestions
    }
}

private struct JobSuggestResponseDTO: Decodable {
    let suggestions: [String]
}
