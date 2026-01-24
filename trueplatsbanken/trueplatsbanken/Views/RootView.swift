import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppStateViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        let _ = languageStore.language

        ZStack(alignment: .topTrailing) {
            TabView(selection: $appState.selectedTab) {
                JobListView(viewModel: appState.jobListViewModel)
                    .tabItem {
                        Label(AppStrings.jobsTitle, systemImage: "briefcase")
                    }
                    .tag(AppStateViewModel.Tab.jobs)

                MatchResultsView(
                    viewModel: appState.matchResultsViewModel,
                    onRefresh: appState.refreshMatches
                )
                .tabItem {
                    Label(AppStrings.matchesTitle, systemImage: "checkmark.seal")
                }
                .tag(AppStateViewModel.Tab.matches)

                ProfileEditorView(
                    viewModel: appState.profileEditorViewModel,
                    onSaved: {
                        await appState.refreshMatches()
                    }
                )
                .tabItem {
                    Label(AppStrings.profileTitle, systemImage: "person")
                }
                .tag(AppStateViewModel.Tab.profile)
            }

            Button(action: { languageStore.toggle() }) {
                Text(languageStore.buttonLabel)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            .padding(.top, 6)
            .padding(.trailing, 12)
        }
        .task {
            await appState.bootstrap()
        }
    }
}
