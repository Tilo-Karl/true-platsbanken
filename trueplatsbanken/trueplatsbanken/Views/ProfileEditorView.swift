import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let matchesCount: Int
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
    private let heroHeight: CGFloat = 300

    var body: some View {
        let _ = languageStore.language

        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    heroSection()
                    
                    profileCard()
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .top)
            .coordinateSpace(name: "SCROLL")
        }
        .overlay(alignment: .top) {
            headerOverlay()
        }
        .confirmationDialog(
            AppStrings.profileReplaceConfirmTitle,
            isPresented: $viewModel.shouldConfirmReplacement
        ) {
            Button(AppStrings.profileReplaceConfirmAction) {
                Task { await viewModel.confirmReplace() }
            }
            Button(AppStrings.profileReplaceCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.profileReplaceConfirmMessage)
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
        .sheet(isPresented: $showUploadSheet) {
            uploadSheetContent()
        }
        .onAppear {
            heroImageName = heroImages.randomElement() ?? heroImageName
        }
    }

    // MARK: - Component Views

    private func headerOverlay() -> some View {
        HStack(alignment: .center) {
            Text(AppStrings.appTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.brandWhite)
            
            Spacer()
            
            Button(action: { languageStore.toggle() }) {
                Text(languageStore.buttonLabel)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50) // BUMPED UP: Just enough to be under the clock/battery
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    AppColors.brandBlueDark.opacity(0.2), // Your light opacities
                    AppColors.brandBlueDark.opacity(0.4),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea(edges: .top)
    }

    private func heroSection() -> some View {
        let title = isLiveMode ? AppStrings.profileAiActive : AppStrings.profileDemoActive
        let updated = viewModel.lastUpdated ?? Date()
        let subtitle = AppStrings.profileHeroSubtitle(matchesCount, formatDate(updated))

        return GeometryReader { proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            let height = heroHeight + (minY > 0 ? minY : 0)
            
            ZStack(alignment: .bottomLeading) {
                Image(heroImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: height)
                    .clipped()
                    .offset(y: minY > 0 ? -minY : 0)

                VStack(alignment: .leading, spacing: 8) {
                    Spacer() // THIS pushes the text to the bottom, away from the header
                    
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.brandWhite)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppColors.brandWhite.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)

                    Button(AppStrings.profileViewMatches) {
                        onViewMatches()
                    }
                    .font(.headline)
                    .foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .frame(height: heroHeight)
    }

    // --- Rest of methods (profileCard, handlers, etc.) stay exactly as they were ---
    private func profileCard() -> some View {
        let roles = normalizedRoles(viewModel.aiResult?.roles)
        let inferred = normalizedRoles(viewModel.aiResult?.inferredRoles)

        return VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.profileCardTitle)
                .font(.headline)
                .foregroundStyle(AppColors.brandBlack.opacity(0.9))

            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.profileAiRoles)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if roles.isEmpty {
                    Text(AppStrings.profileAiNone).font(.subheadline).foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(roles, id: \.self) { role in
                            ChipView(text: role, style: .primary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.profileAiInferredRoles)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if inferred.isEmpty {
                    Text(AppStrings.profileAiNone).font(.subheadline).foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(inferred, id: \.self) { role in
                            ChipView(text: role, style: .secondary)
                        }
                    }
                }
            }

            DisclosureGroup(isExpanded: $showCvDetails) {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.isDemoProfile {
                        Text(AppStrings.profileDemoCvBadge)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(AppColors.brandGreen)
                            .padding(.vertical, 4).padding(.horizontal, 8)
                            .background(AppColors.brandBlueDark.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    TextEditor(text: $viewModel.draft.cvText)
                        .frame(minHeight: 140)
                        .disabled(true)
                }
            } label: {
                Text(AppStrings.profileSectionCv)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.9))
            }

            Button(AppStrings.profileUploadNewCv) { showUploadSheet = true }
            .font(.headline).foregroundStyle(AppColors.brandWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColors.brandBlueDark)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(AppColors.brandWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
    }

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
            showUploadSheet = false
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
                showUploadSheet = false
                await onUploadFiles(urls)
            }
        case .failure:
            uploadError = AppStrings.profileImportFailed
        }
    }

    private func uploadSheetContent() -> some View {
        VStack(spacing: 16) {
            Text(AppStrings.profileHeroUpload).font(.headline).padding(.top, 12)
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 2, matching: .images) {
                Text(AppStrings.matchesOverlayUploadPhoto)
                    .font(.headline).foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button { showFileImporter = true } label: {
                Text(AppStrings.matchesOverlayUploadFile)
                    .font(.headline).foregroundStyle(AppColors.brandBlueDark)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(AppColors.brandBlueDark.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            if let uploadError {
                Text(uploadError).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(20)
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func normalizedRoles(_ roles: [String]?) -> [String] {
        guard let roles else { return [] }
        return roles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

}

private struct ChipView: View {
    enum Style { case primary; case secondary }
    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(style == .primary ? AppColors.brandBlueDark : AppColors.brandBlueDark.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(style == .primary ? AppColors.brandBlueDark.opacity(0.12) : AppColors.brandBlueDark.opacity(0.04))
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
