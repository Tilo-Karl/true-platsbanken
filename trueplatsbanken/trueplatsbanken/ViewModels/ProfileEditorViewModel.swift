import Foundation

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let profileReader: ProfileReading
    private let profileWriter: ProfileWriting

    init(profileReader: ProfileReading, profileWriter: ProfileWriting) {
        self.profileReader = profileReader
        self.profileWriter = profileWriter
    }

    func loadProfile() async {
        do {
            if let profile = try await profileReader.loadProfile() {
                applyProfile(profile)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile() async {
        isSaving = true
        errorMessage = nil

        let profile = ProfileBuilder.buildProfile(from: draft)

        do {
            try await profileWriter.saveProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func currentProfile() -> Profile {
        return ProfileBuilder.buildProfile(from: draft)
    }

    private func applyProfile(_ profile: Profile) {
        draft.userId = profile.userId
        draft.name = profile.name
        draft.email = profile.email
        draft.phone = profile.phone
        draft.municipality = profile.municipality
        draft.employmentType = profile.employmentType
        draft.skillsText = profile.skills.joined(separator: ", ")
        draft.cvText = profile.cvText
    }

}
