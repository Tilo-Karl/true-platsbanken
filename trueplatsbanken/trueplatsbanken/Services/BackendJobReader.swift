import Foundation

final class BackendJobReader: JobReading {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL ?? BackendServiceURLProvider.baseURL()
        self.session = session
    }

    func fetchJobs() async throws -> [Job] {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("jobs")
        url.append(queryItems: [
            URLQueryItem(name: "limit", value: "50")
        ])

        print("BackendJobReader URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(JobListResponse.self, from: data)
        return payload.jobs
    }
}

private struct JobListResponse: Decodable {
    let jobs: [Job]
    let nextCursor: String?
    let count: Int
}
