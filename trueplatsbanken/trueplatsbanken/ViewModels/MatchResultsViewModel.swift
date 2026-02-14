import Foundation

@MainActor
final class MatchResultsViewModel: ObservableObject {
    @Published private(set) var matches: [MatchResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let matchReader: MatchReading
    private let demoReader: MatchReading
    private let embeddingCache: EmbeddingCaching

    init(
        matchReader: MatchReading,
        demoReader: MatchReading = DemoMatchReader(),
        embeddingCache: EmbeddingCaching = EmbeddingCacheStore()
    ) {
        self.matchReader = matchReader
        self.demoReader = demoReader
        self.embeddingCache = embeddingCache
    }

    func loadMatches(payload: ProfileMatchPayload) async {
        await performLoad {
            let embedding = try? embeddingCache.loadEmbedding(for: payload)
            return try await matchReader.fetchMatches(for: payload, profileEmbedding: embedding)
        }
    }

    func loadDemoMatches() async {
        await performLoad {
            try await demoReader.fetchMatches(for: .demo, profileEmbedding: nil)
        }
    }

    private func performLoad(_ operation: () async throws -> [MatchResult]) async {
        isLoading = true
        errorMessage = nil

        do {
            matches = try await operation()
        } catch {
            errorMessage = error.localizedDescription
            matches = []
        }

        isLoading = false
    }
}
