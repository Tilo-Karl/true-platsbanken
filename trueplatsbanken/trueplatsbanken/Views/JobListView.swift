import SwiftUI

struct JobListView: View {
    @ObservedObject var viewModel: JobListViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        let _ = languageStore.language

        Group {
            if viewModel.isLoading {
                ProgressView(AppStrings.jobsLoading)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(AppStrings.jobsUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
            } else if viewModel.jobs.isEmpty {
                ContentUnavailableView(AppStrings.noJobs, systemImage: "tray", description: Text(AppStrings.checkBackLater))
            } else {
                List(viewModel.jobs) { job in
                    NavigationLink(value: job) {
                        JobListRow(job: job)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(AppStrings.jobsTitle)
        .refreshable {
            await viewModel.loadJobs()
        }
    }
}
