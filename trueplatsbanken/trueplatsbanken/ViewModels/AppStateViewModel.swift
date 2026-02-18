import Foundation

@MainActor
final class AppStateViewModel: ObservableObject {
    enum Tab: Hashable {
        case jobs
        case matches
        case profile
    }

    enum MatchMode {
        case demo
        case live
    }

    @Published var selectedTab: Tab = .profile
    @Published var matchMode: MatchMode = .demo

    let jobListViewModel: JobListViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let matchResultsViewModel: MatchResultsViewModel
    let taxonomyViewModel: TaxonomyViewModel
    private let embeddingCache: EmbeddingCaching
    private let paymentProcessor: PaymentProcessing

    init(
        jobReader: JobReading = BackendJobReader(),
        profileStore: ProfileStateReading & ProfileStateWriting = ProfileLocalStore(),
        matchReader: MatchReading = BackendMatchReader(),
        demoMatchReader: MatchReading = DemoMatchReader(),
        profileExtractor: BackendProfileExtractor = BackendProfileExtractor(),
        roleExpander: BackendRoleExpander = BackendRoleExpander(),
        taxonomyReader: TaxonomyReading = JobTechTaxonomyReader(),
        taxonomyCache: TaxonomyCaching = TaxonomyCacheStore(),
        paymentProcessor: PaymentProcessing = StubPaymentProcessor()
    ) {
        self.embeddingCache = EmbeddingCacheStore()
        self.paymentProcessor = paymentProcessor
        self.jobListViewModel = JobListViewModel(jobReader: jobReader)
        self.profileEditorViewModel = ProfileEditorViewModel(
            profileReader: profileStore,
            profileWriter: profileStore,
            profileExtractor: profileExtractor,
            roleExpander: roleExpander,
            embeddingCache: embeddingCache
        )
        self.matchResultsViewModel = MatchResultsViewModel(
            matchReader: matchReader,
            demoReader: demoMatchReader,
            embeddingCache: embeddingCache
        )
        self.taxonomyViewModel = TaxonomyViewModel(
            reader: taxonomyReader,
            cache: taxonomyCache
        )
    }

    func bootstrap(language: AppLanguageStore.Language) async {
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
        await jobListViewModel.loadJobs()
        let hasProfile = await profileEditorViewModel.loadProfile()
        if matchMode == .demo && !hasProfile {
            profileEditorViewModel.loadDemoProfile()
        }
        await refreshMatches()
    }

    func consumeSharedCVIfAvailable() async {
        guard let text = SharedCVStore.consumeText() else {
            return
        }

        selectedTab = .profile
        await profileEditorViewModel.handleSharedText(text)
    }

    func refreshMatches() async {
        switch matchMode {
        case .demo:
            await matchResultsViewModel.loadDemoMatches()
        case .live:
            guard let payload = profileEditorViewModel.matchPayload() else {
                return
            }
            await matchResultsViewModel.loadMatches(payload: payload, persist: true)
        }
    }

    func handleMatchUploadPhotos(_ data: [Data]) async {
        guard !data.isEmpty else { return }
        await profileEditorViewModel.importFromPhotos(data)
        selectedTab = .profile
    }

    func handleMatchUploadFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        await profileEditorViewModel.importFromFiles(urls)
        selectedTab = .profile
    }

    func handleHeroUploadPhotos(_ data: [Data]) async {
        guard !data.isEmpty else { return }
        do {
            try await paymentProcessor.charge(amount: MatchPricing.priceSek, currency: "SEK")
            await profileEditorViewModel.importFromPhotos(data)
            guard profileEditorViewModel.canMatch else { return }
            matchMode = .live
            await refreshMatches()
        } catch {
            // TODO: surface payment failure to the user
        }
    }

    func handleHeroUploadFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        do {
            try await paymentProcessor.charge(amount: MatchPricing.priceSek, currency: "SEK")
            await profileEditorViewModel.importFromFiles(urls)
            guard profileEditorViewModel.canMatch else { return }
            matchMode = .live
            await refreshMatches()
        } catch {
            // TODO: surface payment failure to the user
        }
    }

    func runPaidMatch() async {
        guard !profileEditorViewModel.isDemoProfile else { return }
        guard let payload = profileEditorViewModel.matchPayload() else { return }
        do {
            try await paymentProcessor.charge(amount: MatchPricing.priceSek, currency: "SEK")
            matchMode = .live
            await matchResultsViewModel.loadMatches(payload: payload, persist: true)
            selectedTab = .matches
        } catch {
            // TODO: surface payment failure to the user
        }
    }

    func refreshTaxonomy(language: AppLanguageStore.Language) async {
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
    }
}
