import Foundation

@MainActor
final class MatchResultsViewModel: ObservableObject {
    @Published private(set) var matches: [MatchResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let matchReader: MatchReading

    init(matchReader: MatchReading) {
        self.matchReader = matchReader
    }

    func loadMatches(profile: Profile) async {
        isLoading = true
        errorMessage = nil

        do {
            matches = try await matchReader.fetchMatches(for: profile)
        } catch {
            errorMessage = error.localizedDescription
            matches = []
        }

        isLoading = false
    }
}
