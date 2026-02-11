import Foundation

struct JobTechAPIConfiguration {
    let baseURL: URL
    let searchPath: String
    let limit: Int

    static func `default`() -> JobTechAPIConfiguration {
        return JobTechAPIConfiguration(
            baseURL: URL(string: "https://jobsearch.api.jobtechdev.se")!,
            searchPath: "/search",
            limit: 50
        )
    }
}

final class JobTechJobReader: JobReading {
    private let configuration: JobTechAPIConfiguration
    private let session: URLSession

    init(
        configuration: JobTechAPIConfiguration = .default(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func fetchJobs(filters: JobFilterState?) async throws -> [Job] {
        var url = configuration.baseURL
        url.append(path: configuration.searchPath)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "limit", value: String(configuration.limit))
        ]
        if let filters {
            queryItems.append(contentsOf: jobTechQueryItems(for: filters))
        }
        url.append(queryItems: queryItems)

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(JobTechSearchResponse.self, from: data)
        return payload.hits.compactMap { hit in
            let id = String(hit.id ?? "")
            if id.isEmpty {
                return nil
            }

            return Job(
                id: id,
                title: hit.headline ?? "",
                description: hit.description?.text ?? "",
                employerName: hit.employer?.name ?? "",
                employerWorkplace: hit.employer?.workplace,
                municipality: hit.workplaceAddress?.municipality ?? "",
                employmentType: hit.employmentType?.label ?? "",
                employmentTypeLabel: hit.employmentType?.label,
                workingHoursTypeLabel: hit.workingHoursType?.label,
                durationLabel: hit.duration?.label,
                scopeOfWorkLabel: hit.scopeOfWork?.label,
                scopeOfWork: ScopeOfWork(
                    min: hit.scopeOfWork?.min,
                    max: hit.scopeOfWork?.max,
                    label: hit.scopeOfWork?.label
                ),
                salaryDescription: hit.salaryDescription,
                conditions: hit.description?.conditions,
                applicationDetailsUrl: hit.applicationDetails?.url.flatMap(URL.init(string:)),
                logoUrl: hit.logoUrl.flatMap(URL.init(string:)),
                lastPublicationDate: hit.lastPublicationDate,
                applicationDeadline: hit.applicationDeadline,
                numberOfVacancies: hit.numberOfVacancies,
                occupationLabel: hit.occupation?.label,
                occupationGroupLabel: hit.occupationGroup?.label,
                occupationFieldLabel: hit.occupationField?.label,
                publishedDisplayText: nil,
                publishedBadgeText: nil,
                publishedDateLabel: nil,
                publishedAt: JobDateParsing.parsePublicationDate(hit.publicationDate),
                url: URL(string: hit.webpageURL ?? "")
            )
        }
    }
}

private func jobTechQueryItems(for filters: JobFilterState) -> [URLQueryItem] {
    var items: [URLQueryItem] = []
    if let occupationField = filters.occupationField?.id {
        items.append(URLQueryItem(name: "occupation-field", value: occupationField))
    } else if !filters.occupations.isEmpty {
        items.append(contentsOf: filters.occupations.map {
            URLQueryItem(name: "occupation-name", value: $0.id)
        })
    }
    if !filters.municipalities.isEmpty {
        items.append(contentsOf: filters.municipalities.map {
            URLQueryItem(name: "municipality", value: $0.id)
        })
    }
    if let employmentType = filters.employmentType?.id {
        items.append(URLQueryItem(name: "employment-type", value: employmentType))
    }
    if let workingHoursType = filters.workingHoursType?.id {
        items.append(URLQueryItem(name: "worktime-extent", value: workingHoursType))
    }
    return items
}

private struct JobTechSearchResponse: Decodable {
    let hits: [JobTechHit]
}

private struct JobTechHit: Decodable {
    let id: String?
    let headline: String?
    let description: JobTechDescription?
    let employer: JobTechEmployer?
    let workplaceAddress: JobTechWorkplaceAddress?
    let employmentType: JobTechEmploymentType?
    let workingHoursType: JobTechWorkingHoursType?
    let duration: JobTechDuration?
    let scopeOfWork: JobTechScopeOfWork?
    let applicationDeadline: String?
    let numberOfVacancies: Double?
    let salaryDescription: String?
    let applicationDetails: JobTechApplicationDetails?
    let logoUrl: String?
    let lastPublicationDate: String?
    let occupation: JobTechOccupation?
    let occupationGroup: JobTechOccupationGroup?
    let occupationField: JobTechOccupationField?
    let publicationDate: String?
    let webpageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case headline
        case description
        case employer
        case workplaceAddress = "workplace_address"
        case employmentType = "employment_type"
        case workingHoursType = "working_hours_type"
        case duration
        case scopeOfWork = "scope_of_work"
        case applicationDeadline = "application_deadline"
        case numberOfVacancies = "number_of_vacancies"
        case salaryDescription = "salary_description"
        case applicationDetails = "application_details"
        case logoUrl = "logo_url"
        case lastPublicationDate = "last_publication_date"
        case occupation
        case occupationGroup = "occupation_group"
        case occupationField = "occupation_field"
        case publicationDate = "publication_date"
        case webpageURL = "webpage_url"
    }
}

private struct JobTechDescription: Decodable {
    let text: String?
    let conditions: String?
}

private struct JobTechEmployer: Decodable {
    let name: String?
    let workplace: String?
}

private struct JobTechWorkplaceAddress: Decodable {
    let municipality: String?
}

private struct JobTechEmploymentType: Decodable {
    let label: String?
}

private struct JobTechWorkingHoursType: Decodable {
    let label: String?
}

private struct JobTechDuration: Decodable {
    let label: String?
}

private struct JobTechScopeOfWork: Decodable {
    let min: Double?
    let max: Double?
    let label: String?
}

private struct JobTechOccupation: Decodable {
    let label: String?
}

private struct JobTechOccupationGroup: Decodable {
    let label: String?
}

private struct JobTechOccupationField: Decodable {
    let label: String?
}

private struct JobTechApplicationDetails: Decodable {
    let url: String?
}
