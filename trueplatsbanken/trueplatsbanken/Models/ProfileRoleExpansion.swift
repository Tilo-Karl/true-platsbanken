import Foundation

struct ProfileRoleExpansion: Hashable, Codable {
    let inferredRoles: [String]
    let rationale: [String: String]
    let occupationIds: [String]
    let opportunityProfile: CandidateOpportunityProfile?
    let educationPath: ProfileEducationPath

    init(
        inferredRoles: [String],
        rationale: [String: String],
        occupationIds: [String] = [],
        opportunityProfile: CandidateOpportunityProfile? = nil,
        educationPath: ProfileEducationPath = .empty
    ) {
        self.inferredRoles = inferredRoles
        self.rationale = rationale
        self.occupationIds = occupationIds
        self.opportunityProfile = opportunityProfile
        self.educationPath = educationPath
    }

    private enum CodingKeys: String, CodingKey {
        case inferredRoles
        case rationale
        case occupationIds
        case opportunityProfile
        case educationPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inferredRoles = try container.decodeIfPresent([String].self, forKey: .inferredRoles) ?? []
        rationale = try container.decodeIfPresent([String: String].self, forKey: .rationale) ?? [:]
        occupationIds = try container.decodeIfPresent([String].self, forKey: .occupationIds) ?? []
        opportunityProfile = try container.decodeIfPresent(CandidateOpportunityProfile.self, forKey: .opportunityProfile)
        educationPath = try container.decodeIfPresent(ProfileEducationPath.self, forKey: .educationPath) ?? .empty
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inferredRoles, forKey: .inferredRoles)
        if !rationale.isEmpty {
            try container.encode(rationale, forKey: .rationale)
        }
        if !occupationIds.isEmpty {
            try container.encode(occupationIds, forKey: .occupationIds)
        }
        try container.encodeIfPresent(opportunityProfile, forKey: .opportunityProfile)
        if educationPath.hasAnyItems {
            try container.encode(educationPath, forKey: .educationPath)
        }
    }
}
