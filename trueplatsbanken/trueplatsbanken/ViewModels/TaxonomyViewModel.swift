import Foundation

@MainActor
final class TaxonomyViewModel: ObservableObject {
    @Published private(set) var snapshot: TaxonomySnapshot?
    @Published private(set) var isLoading = false

    private let reader: TaxonomyReading
    private let cache: TaxonomyCaching
    private let maxCacheAge: TimeInterval

    init(
        reader: TaxonomyReading,
        cache: TaxonomyCaching,
        maxCacheAge: TimeInterval = 60 * 60 * 24
    ) {
        self.reader = reader
        self.cache = cache
        self.maxCacheAge = maxCacheAge
    }

    func loadIfNeeded(languageCode: String) async {
        if let cached = loadCachedSnapshot(languageCode: languageCode), isCacheFresh(cached) {
            snapshot = cached
            return
        }

        await refresh(languageCode: languageCode)
    }

    func refresh(languageCode: String) async {
        isLoading = true
        let cached = loadCachedSnapshot(languageCode: languageCode)

        do {
            let snapshot = try await reader.fetchSnapshot(language: languageCode)
            try? cache.saveSnapshot(snapshot)
            self.snapshot = snapshot
        } catch {
            if let cached {
                snapshot = cached
            }
        }

        isLoading = false
    }

    private func loadCachedSnapshot(languageCode: String) -> TaxonomySnapshot? {
        return try? cache.loadSnapshot(for: languageCode)
    }

    private func isCacheFresh(_ snapshot: TaxonomySnapshot) -> Bool {
        let age = Date().timeIntervalSince(snapshot.fetchedAt)
        return age >= 0 && age < maxCacheAge
    }
}
