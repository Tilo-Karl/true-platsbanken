import Foundation

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published private(set) var aiResult: ProfileAIResult?
    @Published private(set) var isSaving = false
    @Published private(set) var isExtracting = false
    @Published private(set) var errorMessage: String?
    @Published var pendingReplacementText: String?
    @Published var shouldConfirmReplacement = false

    private let profileReader: ProfileStateReading
    private let profileWriter: ProfileStateWriting
    private let profileExtractor: BackendProfileExtractor
    private let roleExpander: BackendRoleExpander

    init(
        profileReader: ProfileStateReading,
        profileWriter: ProfileStateWriting,
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
            if let state = try await profileReader.loadState() {
                applyState(state)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile() async {
        isSaving = true
        errorMessage = nil

        do {
            try await profileWriter.saveState(ProfileLocalState(
                draft: draft,
                aiResult: aiResult,
                lastUpdated: Date()
            ))
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func applyCV(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        isExtracting = true
        errorMessage = nil

        draft.cvText = trimmed

        do {
            let extraction = try await profileExtractor.extractProfile(from: trimmed)
            let expansion = try await roleExpander.expandRoles(from: extraction)
            aiResult = ProfileAIResult(
                keywords: extraction.keywords,
                roles: extraction.roles,
                inferredRoles: expansion.inferredRoles,
                seniority: extraction.seniority,
                locations: extraction.locations,
                summary: extraction.summary
            )

            try await profileWriter.saveState(ProfileLocalState(
                draft: draft,
                aiResult: aiResult,
                lastUpdated: Date()
            ))
        } catch {
            errorMessage = error.localizedDescription
        }

        isExtracting = false
    }

    func confirmReplace() async {
        guard let text = pendingReplacementText else {
            return
        }
        pendingReplacementText = nil
        shouldConfirmReplacement = false
        await applyCV(text: text)
    }

    func matchPayload() -> ProfileMatchPayload? {
        guard let aiResult else {
            return nil
        }
        return ProfileMatchPayload.build(from: draft, aiResult: aiResult)
    }

    var canMatch: Bool {
        aiResult != nil
    }

    func scheduleReplacement(with text: String) {
        pendingReplacementText = text
        shouldConfirmReplacement = true
    }

    func handleSharedText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        if aiResult != nil || !draft.cvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scheduleReplacement(with: trimmed)
        } else {
            await applyCV(text: trimmed)
        }
    }

    func setErrorMessage(_ message: String) {
        errorMessage = message
    }

    private func applyState(_ state: ProfileLocalState) {
        draft = state.draft
        aiResult = state.aiResult
    }
}
