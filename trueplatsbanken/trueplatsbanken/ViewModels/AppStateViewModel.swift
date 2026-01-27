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

    init(
        jobReader: JobReading = BackendJobReader(),
        profileStore: ProfileStateReading & ProfileStateWriting = ProfileLocalStore(),
        matchReader: MatchReading = BackendMatchReader(),
        profileExtractor: BackendProfileExtractor = BackendProfileExtractor(),
        roleExpander: BackendRoleExpander = BackendRoleExpander()
    ) {
        self.jobListViewModel = JobListViewModel(jobReader: jobReader)
        self.profileEditorViewModel = ProfileEditorViewModel(
            profileReader: profileStore,
            profileWriter: profileStore,
            profileExtractor: profileExtractor,
            roleExpander: roleExpander
        )
        self.matchResultsViewModel = MatchResultsViewModel(matchReader: matchReader)
    }

    func bootstrap() async {
        await jobListViewModel.loadJobs()
        await profileEditorViewModel.loadProfile()
    }

    func refreshMatches() async {
        guard let payload = profileEditorViewModel.matchPayload() else {
            return
        }
        await matchResultsViewModel.loadMatches(payload: payload)
    }
}
