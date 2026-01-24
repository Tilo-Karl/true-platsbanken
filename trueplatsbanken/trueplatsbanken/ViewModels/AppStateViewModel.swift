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
        jobReader: JobReading = JobTechJobReader(),
        profileStore: ProfileReading & ProfileWriting = FirestoreProfileStore(),
        matchReader: MatchReading = BackendMatchReader()
    ) {
        self.jobListViewModel = JobListViewModel(jobReader: jobReader)
        self.profileEditorViewModel = ProfileEditorViewModel(
            profileReader: profileStore,
            profileWriter: profileStore
        )
        self.matchResultsViewModel = MatchResultsViewModel(matchReader: matchReader)
    }

    func bootstrap() async {
        await jobListViewModel.loadJobs()
        await profileEditorViewModel.loadProfile()
    }

    func refreshMatches() async {
        let profile = profileEditorViewModel.currentProfile()
        await matchResultsViewModel.loadMatches(profile: profile)
    }
}
