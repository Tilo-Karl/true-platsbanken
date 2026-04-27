import UniformTypeIdentifiers
import SwiftUI
import PhotosUI

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    @ObservedObject var matchesViewModel: MatchResultsViewModel
    let isLiveMode: Bool
    let onUploadPhotos: ([Data]) async -> Void
    let onUploadFiles: ([URL]) async -> Void
    let onViewMatches: () -> Void
    @Binding var showUploadSheet: Bool
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var showCvDetails = false
    @State private var heroImageName = "CVMatch11"
    @State private var uploadError: String?

    private let heroImages = ["CVMatch11", "CVMatch12"]
    private let heroHeight: CGFloat = 180
    private let headerOverlapFraction: CGFloat = 1.0 / 3.0

    var body: some View {
        ZStack(alignment: .top) {
            // Background fills everything behind the scroll
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HeroOverlapHeader(
                        heroImageName: heroImageName,
                        heroHeight: heroHeight,
                        topScrim: heroScrim,
                        overlapFraction: headerOverlapFraction,
                        bottomSpacing: AppSpacing.sectionGap
                    ) {
                        statusCard()
                    }

                    rolesCard()
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.bottom, AppSpacing.sectionGap)

                    cvCard()
                        .padding(.horizontal, AppSpacing.screenPadding)
                }
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .top)
            .coordinateSpace(name: "SCROLL")
            
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showUploadSheet) {
            uploadSheetContent()
        }
        .onChange(of: selectedPhotos) { _, items in
            handlePhotoSelection(items)
        }
        .onAppear {
            heroImageName = heroImages.randomElement() ?? heroImageName
        }
    }

    // MARK: - Sections

    private var heroScrim: LinearGradient {
        LinearGradient(
            colors: heroImageName == "CVMatch12"
                ? [AppColors.brandGreen.opacity(0.75), AppColors.brandGreen.opacity(0.25), .clear]
                : [AppColors.brandBlueDark.opacity(0.7), AppColors.brandBlueDark.opacity(0.2), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func statusCard() -> some View {
        HeaderSummaryCard(
            title: isLiveMode ? AppStrings.profileAiActive : AppStrings.profileDemoActive,
            subtitle: AppStrings.profileMatchesFound(matchesViewModel.matches.count)
        ) {
            Button(action: onViewMatches) {
                Text(AppStrings.profileViewMatches)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func rolesCard() -> some View {
        let roles = normalizedRoles(viewModel.aiResult?.roles)
        let inferred = normalizedRoles(viewModel.aiResult?.inferredRoles)

        return SectionCard(title: AppStrings.profileCardTitle) {
            VStack(alignment: .leading, spacing: 24) {
                if !roles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppStrings.profileAiRoles)
                            .font(AppFonts.meta.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(roles, id: \.self) { role in
                                ChipView(text: role, style: .primary)
                            }
                        }
                    }
                }

                if !inferred.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppStrings.profileAiInferredRoles)
                            .font(AppFonts.meta.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(inferred, id: \.self) { role in
                                ChipView(text: role, style: .secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cvCard() -> some View {
        SectionCard(title: AppStrings.profileSectionCv) {
            VStack(alignment: .leading, spacing: 20) {
                DisclosureGroup(isExpanded: $showCvDetails) {
                    TextEditor(text: .constant(viewModel.draft.cvText))
                        .frame(minHeight: 120)
                        .font(AppFonts.meta)
                        .padding(10)
                        .background(AppColors.brandWhite.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(true)
                        .padding(.top, 10)
                } label: {
                    Text(AppStrings.profileDetailsTitle)
                        .font(AppFonts.body)
                        .foregroundStyle(.secondary)
                }

                Button { showUploadSheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.doc.fill")
                        Text(AppStrings.profileUploadNewCv)
                    }
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandBlueDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.brandBlueDark.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: - Helper Methods
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            let dataItems = await loadPhotoData(from: items)
            if let error = UploadValidation.validatePhotoData(dataItems) {
                uploadError = error; selectedPhotos = []; return
            }
            uploadError = nil; showUploadSheet = false
            await onUploadPhotos(dataItems); selectedPhotos = []
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
                showUploadSheet = false
                await onUploadFiles(urls)
            }
        case .failure:
            uploadError = AppStrings.profileImportFailed
        }
    }

    private func uploadSheetContent() -> some View {
        VStack(spacing: 16) {
            Capsule().frame(width: 40, height: 5).foregroundStyle(.secondary).padding(.top, 10)
            Text(AppStrings.profileHeroUpload).font(AppFonts.sectionTitle).padding(.top, 12)
            
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 2, matching: .images) {
                Text(AppStrings.matchesOverlayUploadPhoto)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button { showFileImporter = true } label: {
                Text(AppStrings.matchesOverlayUploadFile)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandBlueDark)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppColors.brandBlueDark.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            if let uploadError {
                Text(uploadError).font(AppFonts.meta).foregroundStyle(.red).padding(.top, 8)
            }
            Spacer()
        }
        .padding(20)
        // Present file picker from the sheet host to avoid "already presenting" conflicts.
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
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

    private func normalizedRoles(_ roles: [String]?) -> [String] {
        guard let roles = roles else { return [] }
        return roles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

}

// MARK: - Reusable Components

private struct ChipView: View {
    enum Style { case primary; case secondary }
    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(AppFonts.meta.weight(.semibold))
            .foregroundStyle(style == .primary ? AppColors.brandBlueDark : AppColors.brandBlack.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(style == .primary ? AppColors.brandBlueDark.opacity(0.12) : AppColors.brandBlack.opacity(0.05))
            .clipShape(Capsule())
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    var body: some View { FlowLayoutContainer(spacing: spacing) { content } }
}

private struct FlowLayoutContainer: Layout {
    let spacing: CGFloat
    init(spacing: CGFloat) { self.spacing = spacing }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var rowWidth: CGFloat = 0; var rowHeight: CGFloat = 0; var totalHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing; rowWidth = 0; rowHeight = 0
            }
            rowWidth += size.width + (rowWidth > 0 ? spacing : 0); rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
    }
}
