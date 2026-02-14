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

    @Published var selectedTab: Tab = .matches
    @Published var matchMode: MatchMode = .demo

    let jobListViewModel: JobListViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let matchResultsViewModel: MatchResultsViewModel
    let taxonomyViewModel: TaxonomyViewModel
    private let embeddingCache: EmbeddingCaching

    init(
        jobReader: JobReading = BackendJobReader(),
        profileStore: ProfileStateReading & ProfileStateWriting = ProfileLocalStore(),
        matchReader: MatchReading = BackendMatchReader(),
        demoMatchReader: MatchReading = DemoMatchReader(),
        profileExtractor: BackendProfileExtractor = BackendProfileExtractor(),
        roleExpander: BackendRoleExpander = BackendRoleExpander(),
        taxonomyReader: TaxonomyReading = JobTechTaxonomyReader(),
        taxonomyCache: TaxonomyCaching = TaxonomyCacheStore()
    ) {
        self.embeddingCache = EmbeddingCacheStore()
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
        await profileEditorViewModel.loadProfile()
        if matchMode == .demo {
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
            await matchResultsViewModel.loadMatches(payload: payload)
        }
    }

    func refreshTaxonomy(language: AppLanguageStore.Language) async {
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
    }
}
