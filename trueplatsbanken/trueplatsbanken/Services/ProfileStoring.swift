import Foundation

protocol ProfileReading {
    func loadProfile() async throws -> Profile?
}

protocol ProfileWriting {
    func saveProfile(_ profile: Profile) async throws
}
