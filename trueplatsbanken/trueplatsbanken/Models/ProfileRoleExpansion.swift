import Foundation

struct ProfileRoleExpansion: Hashable, Codable {
    let inferredRoles: [String]
    let rationale: [String: String]
    let occupationIds: [String]

    init(
        inferredRoles: [String],
        rationale: [String: String],
        occupationIds: [String] = []
    ) {
        self.inferredRoles = inferredRoles
        self.rationale = rationale
        self.occupationIds = occupationIds
    }

    private enum CodingKeys: String, CodingKey {
        case inferredRoles
        case rationale
        case occupationIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inferredRoles = try container.decodeIfPresent([String].self, forKey: .inferredRoles) ?? []
        rationale = try container.decodeIfPresent([String: String].self, forKey: .rationale) ?? [:]
        occupationIds = try container.decodeIfPresent([String].self, forKey: .occupationIds) ?? []
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
    }
}
