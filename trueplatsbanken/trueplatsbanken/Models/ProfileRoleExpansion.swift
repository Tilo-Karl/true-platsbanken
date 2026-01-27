import Foundation

struct ProfileRoleExpansion: Hashable, Codable {
    let inferredRoles: [String]
    let rationale: [String: String]
}
