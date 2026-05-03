import Foundation

struct CandidateOpportunityProfile: Hashable, Codable {
    let primaryDomains: [String]
    let secondaryDomains: [String]
    let transferableCapabilities: [String]
    let workEnvironments: [String]
    let careerStage: String?
    let coreOccupationTargets: [CoreOccupationTarget]
    let pivotOpportunityFamilies: [PivotOpportunityFamily]
    let lowLeverageFamilies: [String]

    static let empty = CandidateOpportunityProfile(
        primaryDomains: [],
        secondaryDomains: [],
        transferableCapabilities: [],
        workEnvironments: [],
        careerStage: nil,
        coreOccupationTargets: [],
        pivotOpportunityFamilies: [],
        lowLeverageFamilies: []
    )

    var hasDebugContent: Bool {
        !primaryDomains.isEmpty ||
        !secondaryDomains.isEmpty ||
        !transferableCapabilities.isEmpty ||
        !pivotOpportunityFamilies.isEmpty
    }
}

struct CoreOccupationTarget: Hashable, Codable {
    let occupationId: String
    let occupationLabel: String
}

struct PivotOpportunityFamily: Hashable, Codable {
    let id: String
    let label: String
    let fitScore: Int?
    let evidenceScore: Int?
    let capabilityScore: Int?
    let occupationIds: [String]
    let occupationSeeds: [String]
    let searchTerms: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case fitScore
        case evidenceScore
        case capabilityScore
        case occupationIds
        case occupationSeeds
        case searchTerms
    }

    init(
        id: String,
        label: String,
        fitScore: Int? = nil,
        evidenceScore: Int? = nil,
        capabilityScore: Int? = nil,
        occupationIds: [String] = [],
        occupationSeeds: [String] = [],
        searchTerms: [String] = []
    ) {
        self.id = id
        self.label = label
        self.fitScore = fitScore
        self.evidenceScore = evidenceScore
        self.capabilityScore = capabilityScore
        self.occupationIds = occupationIds
        self.occupationSeeds = occupationSeeds
        self.searchTerms = searchTerms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        fitScore = try container.decodeIfPresent(Int.self, forKey: .fitScore)
        evidenceScore = try container.decodeIfPresent(Int.self, forKey: .evidenceScore)
        capabilityScore = try container.decodeIfPresent(Int.self, forKey: .capabilityScore)
        occupationIds = try container.decodeIfPresent([String].self, forKey: .occupationIds) ?? []
        occupationSeeds = try container.decodeIfPresent([String].self, forKey: .occupationSeeds) ?? []
        searchTerms = try container.decodeIfPresent([String].self, forKey: .searchTerms) ?? []
    }
}
