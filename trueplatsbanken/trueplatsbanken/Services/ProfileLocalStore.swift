import Foundation

final class ProfileLocalStore: ProfileReading, ProfileWriting {
    private let storage: UserDefaults
    private let key = "profile.draft"

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    func loadProfile() async throws -> Profile? {
        guard let data = storage.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Profile.self, from: data)
    }

    func saveProfile(_ profile: Profile) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        storage.set(data, forKey: key)
    }
}
