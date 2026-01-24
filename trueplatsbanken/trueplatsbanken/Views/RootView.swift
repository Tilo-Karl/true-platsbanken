import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppStateViewModel

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            JobListView(viewModel: appState.jobListViewModel)
                .tabItem {
                    Label("Jobs", systemImage: "briefcase")
                }
                .tag(AppStateViewModel.Tab.jobs)

            MatchResultsView(
                viewModel: appState.matchResultsViewModel,
                onRefresh: appState.refreshMatches
            )
            .tabItem {
                Label("Matches", systemImage: "checkmark.seal")
            }
            .tag(AppStateViewModel.Tab.matches)

            ProfileEditorView(
                viewModel: appState.profileEditorViewModel,
                onSaved: {
                    await appState.refreshMatches()
                }
            )
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(AppStateViewModel.Tab.profile)
        }
        .task {
            await appState.bootstrap()
        }
    }
}
