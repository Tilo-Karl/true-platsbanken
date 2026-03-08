import Foundation
import BackgroundTasks

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
    private let matchUpdateService: MatchUpdateService
    private var didRegisterBackgroundTasks = false
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
        paymentProcessor: PaymentProcessing = StubPaymentProcessor(),
        matchUpdateService: MatchUpdateService = .shared
    ) {
        self.embeddingCache = EmbeddingCacheStore()
        self.paymentProcessor = paymentProcessor
        self.matchUpdateService = matchUpdateService
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
        registerBackgroundTasksIfNeeded()
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
            let loaded = await matchResultsViewModel.loadMatches(payload: payload, persist: true)
            if loaded != nil, matchResultsViewModel.errorMessage == nil {
                matchUpdateService.recordSuccessfulRun()
            }
        }
    }

    func checkForMatchUpdate(trigger: MatchUpdateService.Trigger) async {
        _ = await matchUpdateService.runMatchUpdateIfNeeded(appState: self, trigger: trigger)
    }

    func registerBackgroundTasksIfNeeded() {
        guard !didRegisterBackgroundTasks else { return }
        didRegisterBackgroundTasks = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: MatchUpdateService.taskIdentifier, using: nil) { [weak self] task in
            guard let self, let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            MatchUpdateService.shared.handleBackgroundTask(refreshTask, appState: self)
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
            let previousSnapshot = MatchSnapshotStore().loadSnapshot() ?? []
            let previousLastRun = matchUpdateService.lastMatchRun
            let loaded = await matchResultsViewModel.loadMatches(payload: payload, persist: false)
            if let loaded {
                let marked = matchUpdateService.markNewMatches(loaded, since: previousLastRun, previousSnapshot: previousSnapshot)
                matchResultsViewModel.replaceMatches(marked, persist: true)
                matchUpdateService.recordSuccessfulRun()
            }
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
            let previousSnapshot = MatchSnapshotStore().loadSnapshot() ?? []
            let previousLastRun = matchUpdateService.lastMatchRun
            await refreshMatches()
            if matchResultsViewModel.errorMessage == nil {
                let marked = matchUpdateService.markNewMatches(matchResultsViewModel.matches, since: previousLastRun, previousSnapshot: previousSnapshot)
                matchResultsViewModel.replaceMatches(marked, persist: true)
                matchUpdateService.recordSuccessfulRun()
            }
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
