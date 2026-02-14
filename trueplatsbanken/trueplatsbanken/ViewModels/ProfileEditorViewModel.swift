import Foundation

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published private(set) var aiResult: ProfileAIResult?
    @Published private(set) var isSaving = false
    @Published private(set) var isExtracting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isDemoProfile = false
    @Published var pendingReplacementText: String?
    @Published var shouldConfirmReplacement = false

    private let profileReader: ProfileStateReading
    private let profileWriter: ProfileStateWriting
    private let profileExtractor: BackendProfileExtractor
    private let roleExpander: BackendRoleExpander
    private let localCVReader: LocalCVTextReading
    private let embeddingReader: BackendEmbeddingReader
    private let embeddingCache: EmbeddingCaching

    init(
        profileReader: ProfileStateReading,
        profileWriter: ProfileStateWriting,
        profileExtractor: BackendProfileExtractor,
        roleExpander: BackendRoleExpander,
        localCVReader: LocalCVTextReading = LocalCVTextReader(),
        embeddingReader: BackendEmbeddingReader = BackendEmbeddingReader(),
        embeddingCache: EmbeddingCaching = EmbeddingCacheStore()
    ) {
        self.profileReader = profileReader
        self.profileWriter = profileWriter
        self.profileExtractor = profileExtractor
        self.roleExpander = roleExpander
        self.localCVReader = localCVReader
        self.embeddingReader = embeddingReader
        self.embeddingCache = embeddingCache
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

    func loadDemoProfile() {
        draft = DemoProfileSnapshot.draft
        aiResult = DemoProfileSnapshot.aiResult
        isDemoProfile = true
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
        isDemoProfile = false
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        guard CVEligibility.isLikelyCV(trimmed) else {
            errorMessage = AppStrings.profileCvRejected
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

            if draft.municipality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let inferred = extraction.locations.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if let inferred {
                    draft.municipality = inferred
                }
            }

            if let payload = matchPayload() {
                if let embedding = try? await embeddingReader.fetchProfileEmbedding(for: payload) {
                    try? embeddingCache.saveEmbedding(embedding, for: payload)
                }
            }

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

    var hasCvText: Bool {
        !draft.cvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func scheduleReplacement(with text: String) {
        isDemoProfile = false
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

    func importFromPhotos(_ photoData: [Data]) async {
        do {
            let text = try await localCVReader.extractText(from: photoData)
            await applyCV(text: text)
        } catch {
            errorMessage = mapImportError(error)
        }
    }

    func importFromFiles(_ urls: [URL]) async {
        do {
            let limited = Array(urls.prefix(2))
            let text = try await localCVReader.extractText(from: limited)
            await applyCV(text: text)
        } catch {
            errorMessage = mapImportError(error)
        }
    }

    func setErrorMessage(_ message: String) {
        errorMessage = message
    }

    private func mapImportError(_ error: Error) -> String {
        if let error = error as? LocalCVTextReaderError {
            switch error {
            case .noInput:
                return AppStrings.profileImportNoInput
            case .noReadableText:
                return AppStrings.profileImportNoText
            }
        }
        return AppStrings.profileImportFailed
    }

    private func applyState(_ state: ProfileLocalState) {
        draft = state.draft
        aiResult = state.aiResult
        isDemoProfile = false
    }
}
