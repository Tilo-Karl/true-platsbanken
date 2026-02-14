import SwiftUI

struct MatchResultsView: View {
    @ObservedObject var viewModel: MatchResultsViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let isDemo: Bool
    let onRefresh: () async -> Void
    @State private var showMarketingOverlay = true

    var body: some View {
        let _ = languageStore.language

        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    ProgressView(AppStrings.matchesLoading)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(AppStrings.matchesUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView(AppStrings.noMatches, systemImage: "sparkles", description: Text(AppStrings.refreshToCheck))
                } else {
                    List(viewModel.matches) { match in
                        Button {
                            showMarketingOverlay = true
                        } label: {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .overlay {
            if showMarketingOverlay && !viewModel.matches.isEmpty && !viewModel.isLoading {
                MatchMarketingOverlayView {
                    showMarketingOverlay = false
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                HStack(spacing: 8) {
                    Text(AppStrings.appTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.brandGreen)
                    if isDemo {
                        Text(AppStrings.matchesDemoBadge)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.brandWhite)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(AppColors.brandGreen.opacity(0.35))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                Button(AppStrings.refresh) {
                    Task {
                        await onRefresh()
                    }
                }
                .foregroundStyle(AppColors.brandWhite)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [AppColors.brandBlueDark, AppColors.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)
            )
        }
        .refreshable {
            await onRefresh()
        }
    }
}
