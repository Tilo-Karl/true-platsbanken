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

    init(
        matchReader: MatchReading,
        demoReader: MatchReading = DemoMatchReader(),
        embeddingCache: EmbeddingCaching = EmbeddingCacheStore(),
        snapshotStore: MatchSnapshotWriting = MatchSnapshotStore()
    ) {
        self.matchReader = matchReader
        self.demoReader = demoReader
        self.embeddingCache = embeddingCache
        self.snapshotStore = snapshotStore
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

    private func performLoad(_ operation: () async throws -> [MatchResult]) async -> [MatchResult]? {
        isLoading = true
        errorMessage = nil

        do {
            let loaded = try await operation()
            matches = loaded
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
