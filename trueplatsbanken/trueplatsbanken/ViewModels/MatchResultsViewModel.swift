import Foundation

@MainActor
final class MatchResultsViewModel: ObservableObject {
    @Published private(set) var matches: [MatchResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let matchReader: MatchReading
    private let demoReader: MatchReading
    private let embeddingCache: EmbeddingCaching
    private let snapshotStore: MatchSnapshotWriting
    private let snapshotReader: MatchSnapshotReading

    init(
        matchReader: MatchReading,
        demoReader: MatchReading = DemoMatchReader(),
        embeddingCache: EmbeddingCaching = EmbeddingCacheStore(),
        snapshotStore: MatchSnapshotWriting = MatchSnapshotStore(),
        snapshotReader: MatchSnapshotReading = MatchSnapshotStore()
    ) {
        self.matchReader = matchReader
        self.demoReader = demoReader
        self.embeddingCache = embeddingCache
        self.snapshotStore = snapshotStore
        self.snapshotReader = snapshotReader
    }

    func loadMatches(payload: ProfileMatchPayload, persist: Bool = false) async {
        let loaded = await performLoad {
            let embedding = try? embeddingCache.loadEmbedding(for: payload)
            return try await matchReader.fetchMatches(for: payload, profileEmbedding: embedding)
        }
        if persist, let loaded {
            snapshotStore.saveSnapshot(loaded)
        }
    }

    func loadDemoMatches() async {
        _ = await performLoad {
            try await demoReader.fetchMatches(for: .demo, profileEmbedding: nil)
        }
    }

    func loadSnapshot() -> Bool {
        guard let snapshot = snapshotReader.loadSnapshot(), !snapshot.isEmpty else {
            return false
        }
        matches = snapshot
        errorMessage = nil
        return true
    }

    private func performLoad(_ operation: () async throws -> [MatchResult]) async -> [MatchResult]? {
        isLoading = true
        errorMessage = nil

        do {
            let loaded = try await operation()
            matches = loaded
            let top = loaded.prefix(5).map { "\($0.job.title) | \($0.job.employerName) | score: \($0.score.map { String(format: "%.2f", $0) } ?? "-")" }
            print("[matches] loaded count=\(loaded.count)")
            if !top.isEmpty {
                print("[matches] top5:\n" + top.joined(separator: "\n"))
            }
            isLoading = false
            return loaded
        } catch {
            errorMessage = error.localizedDescription
            matches = []
        }

        isLoading = false
        return nil
    }
}
