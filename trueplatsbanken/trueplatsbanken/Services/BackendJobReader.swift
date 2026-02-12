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

    func fetchJobs(filters: JobFilterState?, query: String?, cursor: String?) async throws -> JobPage {
        var url = baseURL
        url.appendPathComponent("api")
        url.appendPathComponent("jobs")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "100")
        ]
        if let cursor, !cursor.isEmpty {
            queryItems.append(URLQueryItem(name: "offset", value: cursor))
        }
        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if let filters {
            queryItems.append(contentsOf: BackendJobQueryBuilder.queryItems(for: filters))
        }
        url.append(queryItems: queryItems)

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let payload = try decoder.decode(JobListResponseDTO.self, from: data)
        return JobPage(jobs: payload.jobs.map { $0.asJob() }, nextCursor: payload.nextCursor)
    }
}

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
private enum BackendJobQueryBuilder {
    static func queryItems(for filters: JobFilterState) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if let occupationField = filters.occupationField?.id {
            items.append(URLQueryItem(name: "occupation_field_id", value: occupationField))
        } else if !filters.occupations.isEmpty {
            items.append(contentsOf: filters.occupations.map {
                URLQueryItem(name: "occupation_ids[]", value: $0.id)
            })
        }

        if !filters.municipalities.isEmpty {
            items.append(contentsOf: filters.municipalities.map {
                URLQueryItem(name: "municipality_ids[]", value: $0.id)
            })
        }

        if let employmentType = filters.employmentType?.id {
            items.append(URLQueryItem(name: "employment_type_id", value: employmentType))
        }

        if let workingHoursType = filters.workingHoursType?.id {
            items.append(URLQueryItem(name: "working_hours_type_id", value: workingHoursType))
        }

        return items
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
