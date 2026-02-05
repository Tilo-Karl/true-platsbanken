import SwiftUI

struct JobListView: View {
    @ObservedObject var viewModel: JobListViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        let _ = languageStore.language

        List {
            ForEach(viewModel.jobs) { job in
                NavigationLink(value: job) {
                    JobListRow(job: job)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isLoading && viewModel.jobs.isEmpty {
                ProgressView(AppStrings.jobsLoading)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(AppStrings.jobsUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
            } else if viewModel.jobs.isEmpty {
                ContentUnavailableView(AppStrings.noJobs, systemImage: "tray", description: Text(AppStrings.checkBackLater))
            }
        }
        .navigationTitle(AppStrings.jobsTitle)
        .refreshable {
            await viewModel.loadJobs()
        }
    }
}
