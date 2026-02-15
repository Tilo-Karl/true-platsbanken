import Foundation

protocol MatchSnapshotReading {
    func loadSnapshot() -> [MatchResult]?
}

protocol MatchSnapshotWriting {
    func saveSnapshot(_ matches: [MatchResult])
}

final class MatchSnapshotStore: MatchSnapshotReading, MatchSnapshotWriting {
    private let defaults: UserDefaults
    private let key = "matches.snapshot.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSnapshot() -> [MatchResult]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([MatchResult].self, from: data)
    }

    func saveSnapshot(_ matches: [MatchResult]) {
        guard let data = try? JSONEncoder().encode(matches) else { return }
        defaults.set(data, forKey: key)
    }
}
