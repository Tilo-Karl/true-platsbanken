import Foundation

struct ProfileAIResult: Hashable, Codable {
    let keywords: [String]
    let roles: [String]
    let inferredRoles: [String]
    let seniority: String?
    let locations: [String]
    let summary: String
    let occupationIds: [String]

    init(
        keywords: [String],
        roles: [String],
        inferredRoles: [String],
        seniority: String?,
        locations: [String],
        summary: String,
        occupationIds: [String] = []
    ) {
        self.keywords = keywords
        self.roles = roles
        self.inferredRoles = inferredRoles
        self.seniority = seniority
        self.locations = locations
        self.summary = summary
        self.occupationIds = occupationIds
    }

    private enum CodingKeys: String, CodingKey {
        case keywords
        case roles
        case inferredRoles
        case seniority
        case locations
        case summary
        case occupationIds
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
    }
}
