import Foundation

protocol TaxonomyReading {
    func fetchSnapshot(language: String) async throws -> TaxonomySnapshot
}

final class JobTechTaxonomyReader: TaxonomyReading {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "https://taxonomy.api.jobtechdev.se/v1/taxonomy/main/concepts")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchSnapshot(language: String) async throws -> TaxonomySnapshot {
        let occupationFields = try await fetchAll(type: .occupationField)
        let occupationGroups = try await fetchAll(type: .occupationGroup)
        let occupations = try await fetchAll(type: .occupationName)
        let regions = try await fetchAll(type: .region)
        let municipalities = try await fetchAll(type: .municipality)
        let employmentTypes = try await fetchAll(type: .employmentType)
        let workingHoursTypes = try await fetchAll(type: .worktimeExtent)

        return TaxonomySnapshot(
            language: language.lowercased(),
            fetchedAt: Date(),
            occupationFields: occupationFields,
            occupationGroups: occupationGroups,
            occupations: occupations,
            regions: regions,
            municipalities: municipalities,
            employmentTypes: employmentTypes,
            workingHoursTypes: workingHoursTypes
        )
    }

    private func fetchAll(type: TaxonomyType) async throws -> [TaxonomyItem] {
        return try await fetchPage(type: type)
    }

    private func fetchPage(type: TaxonomyType) async throws -> [TaxonomyItem] {
        var url = baseURL
        url.append(queryItems: [
            URLQueryItem(name: "type", value: type.rawValue)
        ])

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, urlResponse) = try await session.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([TaxonomyItemDTO].self, from: data)
        return decoded.compactMap { $0.asTaxonomyItem() }
    }
}

private enum TaxonomyType: String {
    case occupationGroup = "occupation-group"
    case occupationField = "occupation-field"
    case occupationName = "occupation-name"
    case employmentType = "employment-type"
    case worktimeExtent = "worktime-extent"
    case region = "region"
    case municipality = "municipality"
}

private struct TaxonomyItemDTO: Decodable {
    let id: String?
    let preferredLabel: String?

    enum CodingKeys: String, CodingKey {
        case id = "taxonomy/id"
        case preferredLabel = "taxonomy/preferred-label"
    }

    func asTaxonomyItem() -> TaxonomyItem? {
        let resolvedId = id ?? ""
        let resolvedLabel = preferredLabel ?? ""
        guard !resolvedId.isEmpty, !resolvedLabel.isEmpty else {
            return nil
        }
        return TaxonomyItem(id: resolvedId, label: resolvedLabel)
    }
}
