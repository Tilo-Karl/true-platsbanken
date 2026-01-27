import Foundation

final class BackendProfileExtractor {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = BackendServiceURLProvider.baseURL(),
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func extractProfile(from text: String) async throws -> ProfileExtractionResult {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("profile")
        url.appendPathComponent("extract")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ExtractionRequest(text: text)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ProfileExtractionResult.self, from: data)
    }
}

private struct ExtractionRequest: Encodable {
    let text: String
}
