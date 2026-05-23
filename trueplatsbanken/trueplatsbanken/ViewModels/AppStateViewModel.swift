import Foundation
import BackgroundTasks
import StoreKit

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
    @Published var isBootstrapping = true
    @Published var matchPaymentPrice: String?
    @Published private(set) var isPaymentAvailable = false
    @Published private(set) var isPaymentMetadataLoading = true
    @Published private(set) var hasActiveEntitlement = false
    @Published private(set) var entitlementPaidUntil: Date?
    @Published var paymentErrorMessage: String?
    @Published private(set) var isPaymentInProgress = false

    let jobListViewModel: JobListViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let matchResultsViewModel: MatchResultsViewModel
    let taxonomyViewModel: TaxonomyViewModel
    private let embeddingCache: EmbeddingCaching
    private let paymentProcessor: PaymentProcessing
    private let storeKitProductCatalog: StoreKitProductCataloging
    private let matchUpdateService: MatchUpdateService
    private var didRegisterBackgroundTasks = false
    private var pendingUpload: PendingUpload?
    var pendingUploadSummary: String? {
        guard let pendingUpload else { return nil }
        switch pendingUpload {
        case .photos(let items):
            return AppStrings.uploadSuccessPhotos(items.count)
        case .files(let urls):
            return AppStrings.uploadSuccessFiles(urls.count)
        }
    }


    var isEntitlementExpiredInLiveMode: Bool {
        matchMode == .live && !hasActiveEntitlement
    }

    var entitlementStatusText: String? {
        guard matchMode == .live else { return nil }

        if hasActiveEntitlement, let entitlementPaidUntil {
            return AppStrings.profileEntitlementActiveUntil(formattedEntitlementDate(entitlementPaidUntil))
        }

        if let entitlementPaidUntil {
            return AppStrings.profileEntitlementExpiredOn(formattedEntitlementDate(entitlementPaidUntil))
        }

        return AppStrings.profileEntitlementExpiredNoHistory
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
        paymentProcessor: PaymentProcessing? = nil,
        storeKitProductCatalog: StoreKitProductCataloging? = nil,
        matchUpdateService: MatchUpdateService = .shared
    ) {
        self.embeddingCache = EmbeddingCacheStore()
        let resolvedProductCatalog = storeKitProductCatalog ?? StoreKitProductCatalog()
        self.storeKitProductCatalog = resolvedProductCatalog
        self.paymentProcessor = paymentProcessor ?? StoreKitPaymentProcessor(productCatalog: resolvedProductCatalog)
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
        refreshEntitlementState()
    }

    func bootstrap(language: AppLanguageStore.Language) async {
        isBootstrapping = true
        defer { isBootstrapping = false }
        refreshEntitlementState()

        Task {
            await loadStoreKitProductMetadata()
        }

        registerBackgroundTasksIfNeeded()
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
        await jobListViewModel.loadJobs()

        let hasSnapshot = matchResultsViewModel.loadSnapshot()
        if hasSnapshot {
            matchMode = .live
        }

        let hasProfile = await profileEditorViewModel.loadProfile()
        if matchMode == .demo && !hasProfile {
            profileEditorViewModel.loadDemoProfile()
        }

        if !hasSnapshot {
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


    func handleSceneDidBecomeActive() async {
        refreshEntitlementState()
        await consumeSharedCVIfAvailable()
        await checkForMatchUpdate(trigger: .appLaunch)
    }

    func refreshMatches() async {
        switch matchMode {
        case .demo:
            await matchResultsViewModel.loadDemoMatches()
        case .live:
            refreshEntitlementState()
            guard hasActiveEntitlement else { return }
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
        refreshEntitlementState()
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
        guard !isPaymentInProgress else { return }
        guard isPaymentAvailable else {
            paymentErrorMessage = AppStrings.paymentErrorUnavailable
            return
        }

        paymentErrorMessage = nil
        isPaymentInProgress = true
        defer { isPaymentInProgress = false }

        do {
            let purchase = try await paymentProcessor.charge(amountCents: MatchPricing.amountCents, currency: MatchPricing.currency)
            try applyVerifiedPurchaseOrThrow(purchase)
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
            handlePaymentFailure(error, source: "runPaidMatch")
        }
    }

    func confirmPayment() async {
        guard pendingUpload != nil else {
            matchFlowStep = .idle
            return
        }
        guard !isPaymentInProgress else { return }
        guard isPaymentAvailable else {
            paymentErrorMessage = AppStrings.paymentErrorUnavailable
            matchFlowStep = .payment
            return
        }

        paymentErrorMessage = nil
        isPaymentInProgress = true
        defer { isPaymentInProgress = false }

        do {
            let purchase = try await paymentProcessor.charge(amountCents: MatchPricing.amountCents, currency: MatchPricing.currency)
            try applyVerifiedPurchaseOrThrow(purchase)
            startProcessing()
        } catch {
            handlePaymentFailure(error, source: "confirmPayment")
            matchFlowStep = .payment
        }
    }

    func cancelPayment() {
        guard !isPaymentInProgress else { return }
        paymentErrorMessage = nil
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
        paymentErrorMessage = nil
        pendingUpload = upload
        refreshEntitlementState()
        if hasActiveEntitlement {
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
            matchFlowStep = .idle
        } else {
            matchFlowStep = .failure
        }
    }

    private func resetPendingUpload() {
        pendingUpload = nil
    }

    private func applyVerifiedPurchaseOrThrow(_ purchase: VerifiedPurchase) throws {
        guard let paidUntil = matchUpdateService.applyVerifiedPurchase(purchase) else {
            throw PaymentProcessingError.unexpectedPurchaseResult
        }
        entitlementPaidUntil = paidUntil
        hasActiveEntitlement = true
    }

    private func refreshEntitlementState(now: Date = Date()) {
        let paidUntil = matchUpdateService.paidUntil
        entitlementPaidUntil = paidUntil
        hasActiveEntitlement = matchUpdateService.isEntitled(now: now)
    }

    private func formattedEntitlementDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func handlePaymentFailure(_ error: Error, source: String) {
        if isPaymentCancellation(error) {
            paymentErrorMessage = nil
            print("[payments] \(source) cancelled by user")
            return
        }

        paymentErrorMessage = paymentFailureMessage(for: error)
        print("[payments] \(source) failed: \(error.localizedDescription)")
    }

    private func isPaymentCancellation(_ error: Error) -> Bool {
        if let paymentError = error as? PaymentProcessingError,
           case .userCancelled = paymentError {
            return true
        }

        let nsError = error as NSError
        guard nsError.domain == SKError.errorDomain,
              let skCode = SKError.Code(rawValue: nsError.code) else {
            return false
        }
        return skCode == .paymentCancelled
    }

    private func paymentFailureMessage(for error: Error) -> String {
        if let paymentError = error as? PaymentProcessingError {
            switch paymentError {
            case .pending:
                return AppStrings.paymentErrorPending
            case .unverified:
                return AppStrings.paymentErrorVerification
            case .userCancelled:
                return ""
            case .unexpectedPurchaseResult:
                return AppStrings.paymentErrorGeneric
            }
        }

        if error is StoreKitProductCatalogError {
            return AppStrings.paymentErrorUnavailable
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut, .dnsLookupFailed:
                return AppStrings.paymentErrorOffline
            default:
                break
            }
        }

        let nsError = error as NSError
        if nsError.domain == SKError.errorDomain {
            switch nsError.code {
            case SKError.Code.storeProductNotAvailable.rawValue,
                 SKError.Code.paymentNotAllowed.rawValue:
                return AppStrings.paymentErrorUnavailable
            // SKErrorCloudServiceNetworkConnectionFailed raw value.
            case 7:
                return AppStrings.paymentErrorOffline
            default:
                return AppStrings.paymentErrorGeneric
            }
        }

        return AppStrings.paymentErrorGeneric
    }

    private func loadStoreKitProductMetadata() async {
        isPaymentMetadataLoading = true
        defer { isPaymentMetadataLoading = false }

        do {
            let product = try await storeKitProductCatalog.matchRunProduct()
            matchPaymentPrice = product.displayPrice
            isPaymentAvailable = true
            print("[payments] StoreKit product loaded id=\(product.id) price=\(product.displayPrice)")
        } catch {
            matchPaymentPrice = nil
            isPaymentAvailable = false
            print("[payments] StoreKit product metadata unavailable for \(MatchPricing.productID): \(error.localizedDescription)")
        }
    }

    func refreshTaxonomy(language: AppLanguageStore.Language) async {
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
    }
}
