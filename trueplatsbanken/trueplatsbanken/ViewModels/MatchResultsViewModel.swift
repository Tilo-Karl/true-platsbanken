import Foundation

@MainActor
final class MatchResultsViewModel: ObservableObject {
    @Published private(set) var matches: [MatchResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let matchReader: MatchReading
    private let embeddingCache: EmbeddingCaching

    init(matchReader: MatchReading, embeddingCache: EmbeddingCaching = EmbeddingCacheStore()) {
        self.matchReader = matchReader
        self.embeddingCache = embeddingCache
    }

    func loadMatches(payload: ProfileMatchPayload) async {
        isLoading = true
        errorMessage = nil

        do {
            let embedding = try? embeddingCache.loadEmbedding(for: payload)
            matches = try await matchReader.fetchMatches(for: payload, profileEmbedding: embedding)
        } catch {
            errorMessage = error.localizedDescription
            matches = []
        }

        isLoading = false
    }
}
