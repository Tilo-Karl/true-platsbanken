import Foundation

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var extractionResult: ProfileExtractionResult?
    @Published private(set) var roleExpansion: ProfileRoleExpansion?

    private let profileReader: ProfileReading
    private let profileWriter: ProfileWriting
    private let profileExtractor: BackendProfileExtractor
    private let roleExpander: BackendRoleExpander

    init(
        profileReader: ProfileReading,
        profileWriter: ProfileWriting,
        profileExtractor: BackendProfileExtractor,
        roleExpander: BackendRoleExpander
    ) {
        self.profileReader = profileReader
        self.profileWriter = profileWriter
        self.profileExtractor = profileExtractor
        self.roleExpander = roleExpander
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
            await refreshExtraction(using: profile)
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

    private func refreshExtraction(using profile: Profile) async {
        let cvText = profile.cvText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cvText.isEmpty else {
            extractionResult = nil
            roleExpansion = nil
            return
        }

        do {
            let extracted = try await profileExtractor.extractProfile(from: cvText)
            extractionResult = extracted
            roleExpansion = try await roleExpander.expandRoles(from: extracted)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
