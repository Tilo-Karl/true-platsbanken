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

    func fetchJobs() async throws -> [Job] {
        var url = configuration.baseURL
        url.append(path: configuration.searchPath)
        url.append(queryItems: [
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "limit", value: String(configuration.limit))
        ])

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

            let publicationInfo = publicationInfo(from: hit.publicationDate)

            return Job(
                id: id,
                title: hit.headline ?? "",
                description: hit.description?.text ?? "",
                employerName: hit.employer?.name ?? "",
                employerWorkplace: hit.employer?.workplace,
                municipality: hit.workplaceAddress?.municipality ?? "",
                employmentType: hit.employmentType?.label ?? "unknown",
                employmentTypeLabel: hit.employmentType?.label,
                workingHoursTypeLabel: hit.workingHoursType?.label,
                durationLabel: hit.duration?.label,
                scopeOfWorkLabel: scopeOfWorkLabel(from: hit.scopeOfWork),
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
                publishedDisplayText: publicationInfo.listLabel,
                publishedBadgeText: publicationInfo.badgeLabel,
                publishedDateLabel: publicationInfo.dateLabel,
                publishedAt: publicationInfo.date,
                url: URL(string: hit.webpageURL ?? "")
            )
        }
    }
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

private func scopeOfWorkLabel(from scope: JobTechScopeOfWork?) -> String? {
    guard let scope else { return nil }
    if let label = scope.label, !label.isEmpty {
        return label
    }
    if let min = scope.min, let max = scope.max {
        if min == max {
            return "\(Int(min))%"
        }
        return "\(Int(min))–\(Int(max))%"
    }
    return nil
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

private struct PublicationInfo {
    let date: Date?
    let listLabel: String?
    let badgeLabel: String?
    let dateLabel: String?
}

private func publicationInfo(from value: String?) -> PublicationInfo {
    guard let value else {
        return PublicationInfo(date: nil, listLabel: nil, badgeLabel: nil, dateLabel: nil)
    }

    let stockholm = TimeZone(identifier: "Europe/Stockholm") ?? .current
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = stockholm

    let date = parseISO8601(value) ?? parseStockholmLocal(value, timeZone: stockholm)
    guard let date else {
        return PublicationInfo(date: nil, listLabel: nil, badgeLabel: nil, dateLabel: nil)
    }

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "sv_SE")
    dateFormatter.timeZone = stockholm
    dateFormatter.dateFormat = "yyyy-MM-dd"

    let timeFormatter = DateFormatter()
    timeFormatter.locale = Locale(identifier: "sv_SE")
    timeFormatter.timeZone = stockholm
    timeFormatter.dateFormat = "HH:mm"

    let isToday = calendar.isDateInToday(date)
    let listLabel: String
    let badgeLabel: String?

    if isToday {
        listLabel = "Publicerad idag, kl \(timeFormatter.string(from: date))"
        badgeLabel = "Ny"
    } else {
        listLabel = "Publicerad \(dateFormatter.string(from: date))"
        badgeLabel = nil
    }

    return PublicationInfo(
        date: date,
        listLabel: listLabel,
        badgeLabel: badgeLabel,
        dateLabel: dateFormatter.string(from: date)
    )
}

private func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) {
        return date
    }
    let fallback = ISO8601DateFormatter()
    return fallback.date(from: value)
}

private func parseStockholmLocal(_ value: String, timeZone: TimeZone) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter.date(from: value)
}
