import Foundation

protocol TaxonomyReading {
    func fetchSnapshot(language: String) async throws -> TaxonomySnapshot
}

final class JobTechTaxonomyReader: TaxonomyReading {
    private let baseURL: URL
    private let session: URLSession
    private let pageSize: Int

    init(
        baseURL: URL = URL(string: "https://taxonomy.api.jobtechdev.se/v1/taxonomy")!,
        session: URLSession = .shared,
        pageSize: Int = 100
    ) {
        self.baseURL = baseURL
        self.session = session
        self.pageSize = pageSize
    }

    func fetchSnapshot(language: String) async throws -> TaxonomySnapshot {
        let languageCode = language.lowercased()
        let occupationFields = try await fetchAll(endpoint: .occupationFields, language: languageCode)
        let occupationGroups = try await fetchAll(endpoint: .occupationGroups, language: languageCode)
        let occupations = try await fetchAll(endpoint: .occupations, language: languageCode)
        let regions = try await fetchAll(endpoint: .regions, language: languageCode)
        let municipalities = try await fetchAll(endpoint: .municipalities, language: languageCode)
        let employmentTypes = try await fetchAll(endpoint: .employmentTypes, language: languageCode)
        let workingHoursTypes = try await fetchAll(endpoint: .workingHoursTypes, language: languageCode)

        return TaxonomySnapshot(
            language: languageCode,
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

    private func fetchAll(endpoint: Endpoint, language: String) async throws -> [TaxonomyItem] {
        var offset = 0
        var results: [TaxonomyItem] = []

        while true {
            let page = try await fetchPage(endpoint: endpoint, language: language, offset: offset)
            if page.isEmpty {
                break
            }
            results.append(contentsOf: page)
            if page.count < pageSize {
                break
            }
            offset += pageSize
        }

        return results
    }

    private func fetchPage(endpoint: Endpoint, language: String, offset: Int) async throws -> [TaxonomyItem] {
        var url = baseURL
        url.appendPathComponent(endpoint.rawValue)
        url.append(queryItems: [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "offset", value: String(offset))
        ])

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let items = try JSONDecoder().decode([TaxonomyItemDTO].self, from: data)
        return items.compactMap { $0.asTaxonomyItem() }
    }
}

private enum Endpoint: String {
    case occupations = "occupations"
    case occupationGroups = "occupation-groups"
    case occupationFields = "occupation-fields"
    case regions = "regions"
    case municipalities = "municipalities"
    case employmentTypes = "employment-types"
    case workingHoursTypes = "working-hours-types"
}

private struct TaxonomyItemDTO: Decodable {
    let id: String?
    let conceptId: String?
    let label: String?
    let preferredLabel: String?

    enum CodingKeys: String, CodingKey {
        case id
        case conceptId = "concept_id"
        case label
        case preferredLabel = "preferred_label"
    }

    func asTaxonomyItem() -> TaxonomyItem? {
        let resolvedId = id ?? conceptId ?? ""
        let resolvedLabel = preferredLabel ?? label ?? ""
        guard !resolvedId.isEmpty, !resolvedLabel.isEmpty else {
            return nil
        }
        return TaxonomyItem(id: resolvedId, label: resolvedLabel)
    }
}
