import SwiftUI

struct MatchResultsView: View {
    @ObservedObject var viewModel: MatchResultsViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let onRefresh: () async -> Void

    var body: some View {
        let _ = languageStore.language

        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView(AppStrings.matchesLoading)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(AppStrings.matchesUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView(AppStrings.noMatches, systemImage: "sparkles", description: Text(AppStrings.refreshToCheck))
                } else {
                    List(viewModel.matches) { match in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(match.job.title)
                                .font(.headline)
                            Text(match.job.employerName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let score = match.score {
                                Text(AppStrings.scoreLabel(Int(score * 100)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(AppStrings.matchesTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppStrings.refresh) {
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
