import Foundation

struct Profile: Identifiable, Hashable, Codable {
    let id: String
    let userId: String
    let name: String
    let email: String
    let phone: String
    let municipality: String
    let employmentType: String
    let skills: [String]
    let cvText: String
}
