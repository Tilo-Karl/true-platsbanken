import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppStateViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let _ = languageStore.language

        NavigationStack {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $appState.selectedTab) {
                    MatchResultsView(
                        viewModel: appState.matchResultsViewModel,
                        isDemo: appState.matchMode == .demo,
                        onUploadPhotos: appState.handleMatchUploadPhotos,
                        onUploadFiles: appState.handleMatchUploadFiles,
                        onRefresh: appState.refreshMatches
                    )
                    .tabItem {
                        Label(AppStrings.matchesTitle, systemImage: "checkmark.seal")
                    }
                    .tag(AppStateViewModel.Tab.matches)

                    JobListView(
                        viewModel: appState.jobListViewModel,
                        taxonomyViewModel: appState.taxonomyViewModel
                    )
                        .tabItem {
                            Label(AppStrings.jobsTitle, systemImage: "briefcase")
                        }
                        .tag(AppStateViewModel.Tab.jobs)

                    ProfileEditorView(
                        viewModel: appState.profileEditorViewModel,
                        onRunPaidMatch: appState.runPaidMatch
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
            .navigationDestination(for: Job.self) { job in
                JobDetailView(job: job)
            }
        }
        .task {
            await appState.bootstrap(language: languageStore.language)
            await appState.consumeSharedCVIfAvailable()
        }
        .onChange(of: languageStore.language) { _, newValue in
            Task {
                await appState.refreshTaxonomy(language: newValue)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await appState.consumeSharedCVIfAvailable()
            }
        }
    }
}
