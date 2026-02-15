import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MatchResultsView: View {
    @ObservedObject var viewModel: MatchResultsViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let isDemo: Bool
    let onUploadPhotos: ([Data]) async -> Void
    let onUploadFiles: ([URL]) async -> Void
    let onRefresh: () async -> Void
    @State private var showMarketingOverlay = true
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var overlayImageName = "CVMatch"

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
                            presentOverlay()
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
            if isDemo && showMarketingOverlay && !viewModel.matches.isEmpty && !viewModel.isLoading {
                MatchMarketingOverlayView(
                    imageName: overlayImageName,
                    selectedPhotos: $selectedPhotos,
                    onUploadFile: {
                        showFileImporter = true
                    },
                    onDismiss: {
                        showMarketingOverlay = false
                    }
                )
            }
        }
        .onAppear {
            if isDemo {
                overlayImageName = randomOverlayImage()
            }
        }
        .onChange(of: selectedPhotos) { _, items in
            guard !items.isEmpty else { return }
            Task {
                let dataItems = await loadPhotoData(from: items)
                await onUploadPhotos(dataItems)
                selectedPhotos = []
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await onUploadFiles(urls)
                }
            case .failure:
                break
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

    private func presentOverlay() {
        overlayImageName = randomOverlayImage()
        showMarketingOverlay = true
    }

    private func randomOverlayImage() -> String {
        let options = ["CVMatch7", "CVMatch8", "CVMatch9", "CVMatch10"]
        return options.randomElement() ?? "CVMatch7"
    }

    private func loadPhotoData(from items: [PhotosPickerItem]) async -> [Data] {
        var results: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                results.append(data)
            }
        }
        return results
    }
}
