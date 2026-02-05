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
        let payload = try decoder.decode(JobListResponseDTO.self, from: data)
        return payload.jobs.map { $0.asJob() }
    }
}

private struct JobListResponseDTO: Decodable {
    let jobs: [JobDTO]
    let nextCursor: String?
    let count: Int
}

private struct JobDTO: Decodable {
    let id: String
    let source: String?
    let url: String?
    let title: String
    let description: String
    let employerName: String
    let employerWorkplace: String?
    let municipality: String
    let employmentType: String
    let employmentTypeLabel: String?
    let workingHoursTypeLabel: String?
    let durationLabel: String?
    let scopeOfWorkLabel: String?
    let scopeOfWork: ScopeOfWork?
    let salaryDescription: String?
    let conditions: String?
    let applicationDetailsUrl: String?
    let logoUrl: String?
    let lastPublicationDate: String?
    let applicationDeadline: String?
    let numberOfVacancies: Double?
    let occupationLabel: String?
    let occupationGroupLabel: String?
    let occupationFieldLabel: String?
    let publishedDisplayText: String?
    let publishedBadgeText: String?
    let publishedDateLabel: String?
    let publishedAt: String?

    func asJob() -> Job {
        Job(
            id: id,
            title: title,
            description: description,
            employerName: employerName,
            employerWorkplace: employerWorkplace,
            municipality: municipality,
            employmentType: employmentType,
            employmentTypeLabel: employmentTypeLabel,
            workingHoursTypeLabel: workingHoursTypeLabel,
            durationLabel: durationLabel,
            scopeOfWorkLabel: scopeOfWorkLabel,
            scopeOfWork: scopeOfWork,
            salaryDescription: salaryDescription,
            conditions: conditions,
            applicationDetailsUrl: URL(string: applicationDetailsUrl ?? ""),
            logoUrl: URL(string: logoUrl ?? ""),
            lastPublicationDate: lastPublicationDate,
            applicationDeadline: applicationDeadline,
            numberOfVacancies: numberOfVacancies,
            occupationLabel: occupationLabel,
            occupationGroupLabel: occupationGroupLabel,
            occupationFieldLabel: occupationFieldLabel,
            publishedDisplayText: publishedDisplayText,
            publishedBadgeText: publishedBadgeText,
            publishedDateLabel: publishedDateLabel,
            publishedAt: parseDate(publishedAt),
            url: URL(string: url ?? "")
        )
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return JobDateParsing.parseISO8601(value)
    }
}
