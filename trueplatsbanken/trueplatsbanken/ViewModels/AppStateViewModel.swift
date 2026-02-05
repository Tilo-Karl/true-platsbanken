import Foundation

@MainActor
final class AppStateViewModel: ObservableObject {
    enum Tab: Hashable {
        case jobs
        case matches
        case profile
    }

    @Published var selectedTab: Tab = .jobs

    let jobListViewModel: JobListViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let matchResultsViewModel: MatchResultsViewModel
    let taxonomyViewModel: TaxonomyViewModel
    private let embeddingCache: EmbeddingCaching

    init(
        jobReader: JobReading = BackendJobReader(),
        profileStore: ProfileStateReading & ProfileStateWriting = ProfileLocalStore(),
        matchReader: MatchReading = BackendMatchReader(),
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
            embeddingCache: embeddingCache
        )
        self.taxonomyViewModel = TaxonomyViewModel(
            reader: taxonomyReader,
            cache: taxonomyCache
        )
    }

    func bootstrap(language: AppLanguageStore.Language) async {
        await jobListViewModel.loadJobs()
        await profileEditorViewModel.loadProfile()
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
    }

    func consumeSharedCVIfAvailable() async {
        guard let text = SharedCVStore.consumeText() else {
            return
        }

        selectedTab = .profile
        await profileEditorViewModel.handleSharedText(text)
    }

    func refreshMatches() async {
        guard let payload = profileEditorViewModel.matchPayload() else {
            return
        }
        await matchResultsViewModel.loadMatches(payload: payload)
    }

    func refreshTaxonomy(language: AppLanguageStore.Language) async {
        await taxonomyViewModel.loadIfNeeded(languageCode: language.rawValue)
    }
}
