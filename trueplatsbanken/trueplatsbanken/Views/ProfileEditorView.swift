import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

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
    private let heroHeight: CGFloat = 180

    var body: some View {
        ZStack {
            // Background gradient: Slightly deeper at the top for better contrast
            LinearGradient(
                colors: [AppColors.brandBlueDark.opacity(0.25), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    
                    // 1. Hero & Status Card Bridge
                    ZStack(alignment: .bottom) {
                        heroSection()
                        
                        statusCard()
                            .padding(.horizontal, 16)
                            .offset(y: 115)
                    }
                    .padding(.bottom, 90)
                    
                    // 2. Your Profile (Roles) Card
                    rolesCard()
                        .padding(.horizontal, 16)

                    // 3. CV Management Card
                    cvCard()
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
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

    // MARK: - Sections

    private func headerOverlay() -> some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            HStack {
                Text(AppStrings.appTitle)
                    .font(.system(size: 18, weight: .semibold))
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
            .padding(.top, 3)
            //.padding(.top, safeTop + 6)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.brandBlueDark.opacity(0.75),
                        AppColors.brandBlueDark.opacity(0.35),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
            )
        }
        .frame(height: 80)
    }

    private func heroSection() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            Image(heroImageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: heroHeight + (minY > 0 ? minY : 0))
                .clipped()
                .offset(y: minY > 0 ? -minY : 0)
        }
        .frame(height: heroHeight)
    }

    private func statusCard() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppColors.brandGreen)
                    .font(.title3)
                Text(isLiveMode ? AppStrings.profileAiActive : AppStrings.profileDemoActive)
                    .font(.headline)
                    .foregroundStyle(AppColors.brandBlueDark)
            }
            
            Text("\(matchesCount) matches found today")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onViewMatches) {
                Text(AppStrings.profileViewMatches)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.85)) // Glassy base
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay( // The "Inner Stroke" for definition
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
    }

    private func rolesCard() -> some View {
        let roles = normalizedRoles(viewModel.aiResult?.roles)
        let inferred = normalizedRoles(viewModel.aiResult?.inferredRoles)

        return VStack(alignment: .leading, spacing: 24) {
            Label(AppStrings.profileCardTitle, systemImage: "person.text.rectangle")
                .font(.headline)
                .foregroundStyle(AppColors.brandBlueDark)

            if !roles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppStrings.profileAiRoles)
                        .font(.caption).bold()
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
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(inferred, id: \.self) { role in
                            ChipView(text: role, style: .secondary)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.4), lineWidth: 0.5)
        )
    }

    private func cvCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(AppStrings.profileSectionCv, systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundStyle(AppColors.brandBlueDark)

            DisclosureGroup(isExpanded: $showCvDetails) {
                TextEditor(text: .constant(viewModel.draft.cvText))
                    .frame(minHeight: 120)
                    .font(.caption)
                    .padding(10)
                    .background(.white.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(true)
                    .padding(.top, 10)
            } label: {
                Text("Tap to review analyzed text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button { showUploadSheet = true } label: {
                HStack {
                    Image(systemName: "arrow.up.doc.fill")
                    Text(AppStrings.profileUploadNewCv)
                }
                .font(.headline)
                .foregroundStyle(AppColors.brandBlueDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.brandBlueDark.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.4), lineWidth: 0.5)
        )
    }

    // MARK: - Handlers & Helpers

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
                    uploadError = error; return
                }
                uploadError = nil; showUploadSheet = false
                await onUploadFiles(urls)
            }
        case .failure: uploadError = AppStrings.profileImportFailed
        }
    }

    private func uploadSheetContent() -> some View {
        VStack(spacing: 16) {
            Capsule().frame(width: 40, height: 5).foregroundStyle(.secondary).padding(.top, 10)
            Text(AppStrings.profileHeroUpload).font(.headline).padding(.top, 12)
            
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 2, matching: .images) {
                Text(AppStrings.matchesOverlayUploadPhoto)
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button { showFileImporter = true } label: {
                Text(AppStrings.matchesOverlayUploadFile)
                    .font(.headline).foregroundStyle(AppColors.brandBlueDark)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppColors.brandBlueDark.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            if let uploadError {
                Text(uploadError).font(.footnote).foregroundStyle(.red).padding(.top, 8)
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

    private func normalizedRoles(_ roles: [String]?) -> [String] {
        guard let roles = roles else { return [] }
        return roles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

// MARK: - Reusable UI Components

private struct ChipView: View {
    enum Style { case primary; case secondary }
    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(style == .primary ? AppColors.brandBlueDark : .primary.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(style == .primary ? AppColors.brandBlueDark.opacity(0.1) : .black.opacity(0.06))
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
