import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppStateViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let _ = languageStore.language

        NavigationStack {
            ZStack {
                TabView(selection: $appState.selectedTab) {
                    ProfileEditorView(
                        viewModel: appState.profileEditorViewModel,
                        matchesCount: appState.matchResultsViewModel.matches.count,
                        isLiveMode: appState.matchMode == .live,
                        onUploadPhotos: appState.handleHeroUploadPhotos,
                        onUploadFiles: appState.handleHeroUploadFiles,
                        onViewMatches: {
                            appState.selectedTab = .matches
                        },
                        showUploadSheet: $appState.showUploadSheet
                    )
                    .tabItem {
                        Label(AppStrings.profileTitle, systemImage: "person")
                    }
                    .tag(AppStateViewModel.Tab.profile)

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
                }

            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                switch appState.matchFlowStep {
                case .idle:
                    EmptyView()
                case .payment:
                    MatchPaymentView(
                        price: MatchPricing.displayPrice,
                        uploadSummary: appState.pendingUploadSummary,
                        onConfirm: {
                            await appState.confirmPayment()
                        },
                        onCancel: {
                            appState.cancelPayment()
                        }
                    )
                case .processing:
                    MatchProcessingView()
                case .failure:
                    MatchFailureView {
                        appState.retryAfterFailure()
                    }
                }
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
