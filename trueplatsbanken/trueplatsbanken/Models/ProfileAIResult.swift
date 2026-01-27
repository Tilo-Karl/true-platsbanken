import Foundation

struct ProfileAIResult: Hashable, Codable {
    let keywords: [String]
    let roles: [String]
    let inferredRoles: [String]
    let seniority: String?
    let locations: [String]
    let summary: String
}
