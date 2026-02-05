import Foundation

protocol TaxonomyCaching {
    func loadSnapshot(for language: String) throws -> TaxonomySnapshot?
    func saveSnapshot(_ snapshot: TaxonomySnapshot) throws
}

final class TaxonomyCacheStore: TaxonomyCaching {
    private let defaults: UserDefaults
    private let keyPrefix = "taxonomy.cache."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSnapshot(for language: String) throws -> TaxonomySnapshot? {
        let key = storageKey(for: language)
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TaxonomySnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: TaxonomySnapshot) throws {
        let key = storageKey(for: snapshot.language)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        defaults.set(data, forKey: key)
    }

    private func storageKey(for language: String) -> String {
        keyPrefix + language
    }
}
