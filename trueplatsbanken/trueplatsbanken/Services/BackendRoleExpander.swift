import Foundation

final class BackendRoleExpander {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = BackendServiceURLProvider.baseURL(),
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func expandRoles(from result: ProfileExtractionResult) async throws -> ProfileRoleExpansion {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("profile")
        url.appendPathComponent("expand-roles")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(result)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ProfileRoleExpansion.self, from: data)
    }
}
