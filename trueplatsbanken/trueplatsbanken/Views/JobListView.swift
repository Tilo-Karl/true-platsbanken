import SwiftUI

struct JobListView: View {
    @ObservedObject var viewModel: JobListViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading jobs...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Jobs unavailable", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.jobs.isEmpty {
                    ContentUnavailableView("No jobs", systemImage: "tray", description: Text("Check back later."))
                } else {
                    List(viewModel.jobs) { job in
                        NavigationLink(value: job) {
                            JobListRow(job: job)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Jobs")
            .navigationDestination(for: Job.self) { job in
                JobDetailView(job: job)
            }
        }
        .refreshable {
            await viewModel.loadJobs()
        }
    }
}
