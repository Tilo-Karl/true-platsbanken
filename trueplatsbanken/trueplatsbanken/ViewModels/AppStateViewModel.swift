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

    enum MatchFlowStep {
        case idle
        case payment
        case processing
        case failure
    }

    @Published var selectedTab: Tab = .profile
    @Published var matchMode: MatchMode = .demo
    @Published var matchFlowStep: MatchFlowStep = .idle
    @Published var showUploadSheet = false

    let jobListViewModel: JobListViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let matchResultsViewModel: MatchResultsViewModel
    let taxonomyViewModel: TaxonomyViewModel
    private let embeddingCache: EmbeddingCaching
    private let paymentProcessor: PaymentProcessing
    private var pendingUpload: PendingUpload?
    private var paidThisSessionForThisRun = false
    var pendingUploadSummary: String? {
        guard let pendingUpload else { return nil }
        switch pendingUpload {
        case .photos(let items):
            return AppStrings.uploadSuccessPhotos(items.count)
        case .files(let urls):
            return AppStrings.uploadSuccessFiles(urls.count)
        }
    }

    private enum PendingUpload {
        case photos([Data])
        case files([URL])
    }

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
        if matchResultsViewModel.loadSnapshot() {
            matchMode = .live
        } else {
            await refreshMatches()
        }
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
        queueUpload(.photos(data))
    }

    func handleMatchUploadFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        queueUpload(.files(urls))
    }

    func handleHeroUploadPhotos(_ data: [Data]) async {
        guard !data.isEmpty else { return }
        queueUpload(.photos(data))
    }

    func handleHeroUploadFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        queueUpload(.files(urls))
    }

    func runPaidMatch() async {
        guard !profileEditorViewModel.isDemoProfile else { return }
        guard let payload = profileEditorViewModel.matchPayload() else { return }
        do {
            try await paymentProcessor.charge(amountCents: MatchPricing.amountCents, currency: MatchPricing.currency)
            matchMode = .live
            await matchResultsViewModel.loadMatches(payload: payload, persist: true)
            selectedTab = .matches
        } catch {
            // TODO: surface payment failure to the user
        }
    }

    func confirmPayment() async {
        guard pendingUpload != nil else {
            matchFlowStep = .idle
            return
        }
        do {
            try await paymentProcessor.charge(amountCents: MatchPricing.amountCents, currency: MatchPricing.currency)
            paidThisSessionForThisRun = true
            startProcessing()
        } catch {
            resetPendingUpload()
            matchFlowStep = .idle
            selectedTab = .profile
        }
    }

    func cancelPayment() {
        resetPendingUpload()
        matchFlowStep = .idle
        selectedTab = .profile
    }

    func retryAfterFailure() {
        matchFlowStep = .idle
        selectedTab = .profile
        showUploadSheet = true
    }

    private func queueUpload(_ upload: PendingUpload) {
        pendingUpload = upload
        if paidThisSessionForThisRun {
            startProcessing()
        } else {
            matchFlowStep = .payment
        }
    }

    private func startProcessing() {
        matchFlowStep = .processing
        Task {
            await runMatchPipeline()
        }
    }

    private func runMatchPipeline() async {
        guard let pendingUpload else {
            matchFlowStep = .idle
            return
        }

        profileEditorViewModel.clearErrorMessage()
        profileEditorViewModel.prepareForNewUpload()

        switch pendingUpload {
        case .photos(let data):
            await profileEditorViewModel.importFromPhotos(data)
        case .files(let urls):
            await profileEditorViewModel.importFromFiles(urls)
        }

        let success = profileEditorViewModel.canMatch
        resetPendingUpload()

        if success {
            matchMode = .live
            await refreshMatches()
            selectedTab = .profile
            paidThisSessionForThisRun = false
            matchFlowStep = .idle
        } else {
            matchFlowStep = .failure
        }
    }

    private func resetPendingUpload() {
        pendingUpload = nil
    }

    func refreshTaxonomy(language: AppLanguageStore.Language) async {
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
    }
}
