import Foundation

protocol RecentSearchesReading {
    func loadRecentSearches() -> [String]
}

protocol RecentSearchesWriting {
    func saveRecentSearches(_ searches: [String])
}

final class RecentSearchesStore: RecentSearchesReading, RecentSearchesWriting {
    private let defaults: UserDefaults
    private let key = "jobs.search.recent"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadRecentSearches() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func saveRecentSearches(_ searches: [String]) {
        defaults.set(searches, forKey: key)
    }
}
