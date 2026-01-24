import SwiftUI

struct MatchResultsView: View {
    @ObservedObject var viewModel: MatchResultsViewModel
    let onRefresh: () async -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading matches...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Matches unavailable", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView("No matches yet", systemImage: "sparkles", description: Text("Refresh to check again."))
                } else {
                    List(viewModel.matches) { match in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(match.job.title)
                                .font(.headline)
                            Text(match.job.employerName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let score = match.score {
                                Text("Score: \(Int(score * 100))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await onRefresh()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}
