import Foundation

struct ProfileExtractionResult: Hashable, Codable {
    let keywords: [String]
    let roles: [String]
    let seniority: String?
    let locations: [String]
    let summary: String
}
