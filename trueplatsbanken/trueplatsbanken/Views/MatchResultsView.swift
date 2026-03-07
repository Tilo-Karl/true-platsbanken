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
    @State private var uploadError: String?
    
    // Using a different hero image for this tab to distinguish it from Profile
    private let heroImageName = "CVMatch12"
    private let heroHeight: CGFloat = 140

    var body: some View {
        let _ = languageStore.language

        ZStack {
            AppBackground()

            ScrollView {
                // Spacing 0 to ensure Header is flush at the top
                VStack(spacing: 0) {
                    StretchyHeaderContainer(
                        heroImageName: heroImageName,
                        heroHeight: heroHeight,
                        topScrim: heroScrim
                    ) {
                        VStack(alignment: .leading, spacing: AppSpacing.cardGap / 2) {
                            HStack {
                                Text(AppStrings.matchesTitle)
                                    .font(AppFonts.title)
                                    .foregroundStyle(AppColors.brandWhite)
                                Spacer()
                                refreshButton
                            }

                            if isDemo {
                                Text(AppStrings.matchesDemoBadge)
                                    .font(AppFonts.meta.weight(.bold))
                                    .foregroundStyle(AppColors.brandWhite)
                                    .padding(.vertical, AppSpacing.cardGap / 3)
                                    .padding(.horizontal, AppSpacing.cardGap)
                                    .background(AppColors.brandAccent.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // The actual list content
                    LazyVStack(spacing: AppSpacing.cardGap) {
                        matchesSection
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, AppSpacing.sectionGap)
                    .padding(.bottom, AppSpacing.sectionGap)
                }
            }
            .coordinateSpace(name: "SCROLL")
            // Match Profile behavior: allow hero to render into the notch.
            .ignoresSafeArea(edges: .top)
            .refreshable {
                await onRefresh()
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
                    },
                    errorMessage: uploadError
                )
            }
        }
        .onAppear {
            if isDemo {
                overlayImageName = randomOverlayImage()
            }
        }
        .onChange(of: selectedPhotos) { _, items in
            handlePhotoSelection(items)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    private var refreshButton: some View {
        Button(action: {
            Task { await onRefresh() }
        }) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.title2)
                .foregroundStyle(AppColors.brandWhite)
        }
        .disabled(viewModel.isLoading)
    }

    @ViewBuilder
    private var matchesSection: some View {
        if viewModel.isLoading {
            VStack {
                ProgressView()
                    .tint(AppColors.brandBlueDark)
                Text(isDemo ? AppStrings.matchesLoading : AppStrings.matchesLoadingLive)
                    .font(AppFonts.meta)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if let error = viewModel.errorMessage {
            ContentUnavailableView(AppStrings.matchesUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
        } else if viewModel.matches.isEmpty {
            ContentUnavailableView(AppStrings.noMatches, systemImage: "sparkles", description: Text(AppStrings.refreshToCheck))
        } else {
            ForEach(viewModel.matches) { match in
                if isDemo {
                    Button {
                        presentOverlay()
                    } label: {
                        MatchCard(match: match)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    NavigationLink(value: match.job) {
                        MatchCard(match: match)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Handlers

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            let dataItems = await loadPhotoData(from: items)
            if let error = UploadValidation.validatePhotoData(dataItems) {
                uploadError = error
                selectedPhotos = []
                return
            }
            uploadError = nil
            showMarketingOverlay = false
            await onUploadPhotos(dataItems)
            selectedPhotos = []
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                if let error = UploadValidation.validateFileUrls(urls) {
                    uploadError = error
                    return
                }
                uploadError = nil
                showMarketingOverlay = false
                await onUploadFiles(urls)
            }
        case .failure:
            uploadError = AppStrings.profileImportFailed
        }
    }

    private func presentOverlay() {
        overlayImageName = randomOverlayImage()
        uploadError = nil
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

    private var heroScrim: LinearGradient {
        LinearGradient(
            colors: [AppColors.brandGreen.opacity(0.75), AppColors.brandGreen.opacity(0.25), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
