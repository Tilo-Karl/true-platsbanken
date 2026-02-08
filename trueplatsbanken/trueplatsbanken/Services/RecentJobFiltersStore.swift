import Foundation

protocol RecentJobFiltersReading {
    func loadRecentFilters() throws -> [JobFilterState]
}

protocol RecentJobFiltersWriting {
    func saveRecentFilters(_ filters: [JobFilterState]) throws
}

final class RecentJobFiltersStore: RecentJobFiltersReading, RecentJobFiltersWriting {
    private let defaults: UserDefaults
    private let key = "job.filters.recent"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadRecentFilters() throws -> [JobFilterState] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        let decoder = JSONDecoder()
        return try decoder.decode([JobFilterState].self, from: data)
    }

    func saveRecentFilters(_ filters: [JobFilterState]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(filters)
        defaults.set(data, forKey: key)
    }
}
