import Foundation

struct MatchResult: Identifiable, Hashable, Codable {
    let id: String
    let job: Job
    let score: Double?
    let reasons: [String]
    var isNewToday: Bool? = nil
}
