import Foundation

struct MatchResult: Identifiable, Hashable {
    let id: String
    let job: Job
    let score: Double?
    let reasons: [String]
}
