import Foundation

final class ProfileLocalStore: ProfileStateReading, ProfileStateWriting {
    private let storage: UserDefaults
    private let key = "profile.local.state"

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    func loadState() async throws -> ProfileLocalState? {
        guard let data = storage.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ProfileLocalState.self, from: data)
    }

    func saveState(_ state: ProfileLocalState) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        storage.set(data, forKey: key)
    }

    func clearState() async throws {
        storage.removeObject(forKey: key)
    }
}
