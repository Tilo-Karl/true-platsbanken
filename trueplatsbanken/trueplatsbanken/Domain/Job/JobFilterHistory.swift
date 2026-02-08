import Foundation

enum JobFilterHistory {
    static func updatedHistory(
        current: [JobFilterState],
        newFilter: JobFilterState,
        limit: Int
    ) -> [JobFilterState] {
        guard !newFilter.isEmpty else {
            return current
        }

        var updated = current.filter { $0 != newFilter }
        updated.insert(newFilter, at: 0)
        if updated.count > limit {
            updated = Array(updated.prefix(limit))
        }
        return updated
    }
}
