import Foundation

final class BackendEmbeddingReader {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL ?? BackendServiceURLProvider.baseURL()
        self.session = session
    }

    func fetchProfileEmbedding(for payload: ProfileMatchPayload) async throws -> [Double] {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("embeddings")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = EmbeddingRequest(profile: payload)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        return decoded.embedding
    }
}

private struct EmbeddingRequest: Encodable {
    let profile: ProfileMatchPayload
}

private struct EmbeddingResponse: Decodable {
    let embedding: [Double]
}
