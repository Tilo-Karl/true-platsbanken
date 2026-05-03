import Foundation

struct ProfileAIResult: Hashable, Codable {
    let keywords: [String]
    let roles: [String]
    let inferredRoles: [String]
    let seniority: String?
    let locations: [String]
    let summary: String
    let occupationIds: [String]
    let opportunityProfile: CandidateOpportunityProfile?
    let educationPath: ProfileEducationPath

    init(
        keywords: [String],
        roles: [String],
        inferredRoles: [String],
        seniority: String?,
        locations: [String],
        summary: String,
        occupationIds: [String] = [],
        opportunityProfile: CandidateOpportunityProfile? = nil,
        educationPath: ProfileEducationPath = .empty
    ) {
        self.keywords = keywords
        self.roles = roles
        self.inferredRoles = inferredRoles
        self.seniority = seniority
        self.locations = locations
        self.summary = summary
        self.occupationIds = occupationIds
        self.opportunityProfile = opportunityProfile
        self.educationPath = educationPath
    }

    private enum CodingKeys: String, CodingKey {
        case keywords
        case roles
        case inferredRoles
        case seniority
        case locations
        case summary
        case occupationIds
        case opportunityProfile
        case educationPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keywords = try container.decode([String].self, forKey: .keywords)
        roles = try container.decode([String].self, forKey: .roles)
        inferredRoles = try container.decode([String].self, forKey: .inferredRoles)
        seniority = try container.decodeIfPresent(String.self, forKey: .seniority)
        locations = try container.decode([String].self, forKey: .locations)
        summary = try container.decode(String.self, forKey: .summary)
        occupationIds = try container.decodeIfPresent([String].self, forKey: .occupationIds) ?? []
        opportunityProfile = try container.decodeIfPresent(CandidateOpportunityProfile.self, forKey: .opportunityProfile)
        educationPath = try container.decodeIfPresent(ProfileEducationPath.self, forKey: .educationPath) ?? .empty
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keywords, forKey: .keywords)
        try container.encode(roles, forKey: .roles)
        try container.encode(inferredRoles, forKey: .inferredRoles)
        try container.encodeIfPresent(seniority, forKey: .seniority)
        try container.encode(locations, forKey: .locations)
        try container.encode(summary, forKey: .summary)
        if !occupationIds.isEmpty {
            try container.encode(occupationIds, forKey: .occupationIds)
        }
        try container.encodeIfPresent(opportunityProfile, forKey: .opportunityProfile)
        if educationPath.hasAnyItems {
            try container.encode(educationPath, forKey: .educationPath)
        }
    }
}
