import Foundation

struct Constraints: Hashable {
    let employmentType: String?
    let locations: [String]
}

struct ProfileSignals: Hashable {
    let keywords: [String]
    let occupations: [String]
    let locations: [String]
    let seniorityHints: [String]
    let constraints: Constraints
}
