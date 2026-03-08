import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MatchResultsView: View {
    @ObservedObject var viewModel: MatchResultsViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let isDemo: Bool
    let onUploadPhotos: ([Data]) async -> Void
    let onUploadFiles: ([URL]) async -> Void
    let onRefresh: (() async -> Void)?
    
    @State private var showMarketingOverlay = true
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var overlayImageName = "CVMatch"
    @State private var uploadError: String?
    
    // Using a different hero image for this tab to distinguish it from Profile
    private let heroImageName = "CVMatch12"
    private let heroHeight: CGFloat = 180
    private let headerOverlapFraction: CGFloat = 1.0 / 3.0

    var body: some View {
        let _ = languageStore.language

        HeroListScreen(
            heroImageName: heroImageName,
            heroHeight: heroHeight,
            topScrim: heroScrim,
            overlapFraction: headerOverlapFraction,
            bottomSpacing: AppSpacing.sectionGap,
            onRefresh: onRefresh
        ) {
            matchesHeaderCard
        } content: {
            matchesSection
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

    private var matchesHeaderCard: some View {
        HeaderSummaryCard(
            title: AppStrings.matchesTitle,
            subtitle: viewModel.isLoading && viewModel.matches.isEmpty
                ? (isDemo ? AppStrings.matchesLoading : AppStrings.matchesLoadingLive)
                : AppStrings.profileMatchesFound(viewModel.matches.count),
            badgeText: isDemo ? AppStrings.matchesDemoBadge : nil,
            badgeBackground: AppColors.brandAccent.opacity(0.5),
            badgeForeground: AppColors.brandWhite
        )
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
