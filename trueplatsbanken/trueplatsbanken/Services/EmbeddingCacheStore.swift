import CryptoKit
import Foundation

protocol EmbeddingCaching {
    func loadEmbedding(for payload: ProfileMatchPayload) throws -> [Double]?
    func saveEmbedding(_ embedding: [Double], for payload: ProfileMatchPayload) throws
    func clear()
}

final class EmbeddingCacheStore: EmbeddingCaching {
    private struct CacheEntry: Codable {
        let key: String
        let version: String
        let embedding: [Double]
    }

    private let storageKey = "profile.embedding.cache"
    private let version = "v1-text-embedding-3-small"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadEmbedding(for payload: ProfileMatchPayload) throws -> [Double]? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }
        let entry = try JSONDecoder().decode(CacheEntry.self, from: data)
        let expectedKey = payload.embeddingCacheKey()
        guard entry.key == expectedKey, entry.version == version else {
            return nil
        }
        return entry.embedding
    }

    func saveEmbedding(_ embedding: [Double], for payload: ProfileMatchPayload) throws {
        let entry = CacheEntry(key: payload.embeddingCacheKey(), version: version, embedding: embedding)
        let data = try JSONEncoder().encode(entry)
        defaults.set(data, forKey: storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}

private extension ProfileMatchPayload {
    func embeddingCacheKey() -> String {
        let text = cvText.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
