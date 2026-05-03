import Foundation

struct MatchResult: Identifiable, Hashable, Codable {
    enum MatchType: String, Hashable, Codable {
        case core
        case pivot
    }

    let id: String
    let job: Job
    let score: Double?
    let reasons: [String]
    let matchType: MatchType
    var isNewToday: Bool? = nil

    init(
        id: String,
        job: Job,
        score: Double?,
        reasons: [String],
        matchType: MatchType = .core,
        isNewToday: Bool? = nil
    ) {
        self.id = id
        self.job = job
        self.score = score
        self.reasons = reasons
        self.matchType = matchType
        self.isNewToday = isNewToday
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case job
        case score
        case reasons
        case matchType
        case isNewToday
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        job = try container.decode(Job.self, forKey: .job)
        score = try container.decodeIfPresent(Double.self, forKey: .score)
        reasons = try container.decodeIfPresent([String].self, forKey: .reasons) ?? []
        matchType = try container.decodeIfPresent(MatchType.self, forKey: .matchType) ?? .core
        isNewToday = try container.decodeIfPresent(Bool.self, forKey: .isNewToday)
    }
}
