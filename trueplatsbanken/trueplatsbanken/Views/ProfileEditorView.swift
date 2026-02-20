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

    var body: some View {
        let _ = languageStore.language

        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    heroSection()
                        .ignoresSafeArea(edges: .top)

                    profileCard()
                        .padding(.horizontal, 16)

            /*
            Section(AppStrings.profileSectionIdentity) {
                TextField(AppStrings.profileUserId, text: $viewModel.draft.userId)
                    .textInputAutocapitalization(.never)
                TextField(AppStrings.profileName, text: $viewModel.draft.name)
                TextField(AppStrings.profileEmail, text: $viewModel.draft.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField(AppStrings.profilePhone, text: $viewModel.draft.phone)
                    .keyboardType(.phonePad)
            }

            Section(AppStrings.profileSectionPreferences) {
                TextField(AppStrings.profileMunicipality, text: $viewModel.draft.municipality)
                Picker(AppStrings.profileEmploymentType, selection: $viewModel.draft.employmentType) {
                    ForEach(EmploymentTypeOptions.all, id: \.self) { type in
                        Text(AppStrings.employmentTypeLabel(for: type))
                    }
                }
            }

            Section(AppStrings.profileSectionSkills) {
                TextField(AppStrings.profileSkillsPlaceholder, text: $viewModel.draft.skillsText)
            }

            ProfileInputView(
                cvText: $viewModel.draft.cvText,
                isExtracting: viewModel.isExtracting,
                onExtract: {
                    Task {
                        await viewModel.applyCV(text: viewModel.draft.cvText)
                    }
                },
                onPaste: {
                    if let text = UIPasteboard.general.string {
                        viewModel.draft.cvText = text
                    }
                },
                onReplace: {
                    viewModel.scheduleReplacement(with: viewModel.draft.cvText)
                }
            )

            if let result = viewModel.aiResult {
                ProfileAIResultView(result: result)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await onMatch()
                    }
                } label: {
                    Text(AppStrings.profileMatch)
                }
                .disabled(!viewModel.canMatch)
            }

            Section {
                Button {
                    Task {
                        await viewModel.saveProfile()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text(AppStrings.saveProfile)
                    }
                }
            }
            */
                }
                .padding(.bottom, 24)
            }
        }
        .overlay(alignment: .top) {
            HStack {
                Text(AppStrings.appTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandGreen)
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
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.brandBlueDark.opacity(0.85),
                        AppColors.brandBlueDark.opacity(0.3),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .confirmationDialog(
            AppStrings.profileReplaceConfirmTitle,
            isPresented: $viewModel.shouldConfirmReplacement
        ) {
            Button(AppStrings.profileReplaceConfirmAction) {
                Task {
                    await viewModel.confirmReplace()
                }
            }
            Button(AppStrings.profileReplaceCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.profileReplaceConfirmMessage)
        }
        .onChange(of: selectedPhotos) { _, items in
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
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
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
        .sheet(isPresented: $showUploadSheet) {
            VStack(spacing: 16) {
                Text(AppStrings.profileHeroUpload)
                    .font(.headline)
                    .padding(.top, 12)
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 2,
                    matching: .images
                ) {
                    Text(AppStrings.matchesOverlayUploadPhoto)
                        .font(.headline)
                        .foregroundStyle(AppColors.brandWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.brandBlueDark)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    showFileImporter = true
                } label: {
                    Text(AppStrings.matchesOverlayUploadFile)
                        .font(.headline)
                        .foregroundStyle(AppColors.brandBlueDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.brandBlueDark.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                if let uploadError {
                    Text(uploadError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(20)
        }
        .onChange(of: showUploadSheet) { _, isPresented in
            if isPresented {
                uploadError = nil
            }
        }
        .onAppear {
            heroImageName = heroImages.randomElement() ?? heroImageName
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func heroSection() -> some View {
        let title = isLiveMode ? AppStrings.profileAiActive : AppStrings.profileDemoActive
        let updated = viewModel.lastUpdated ?? Date()
        let subtitle = AppStrings.profileHeroSubtitle(matchesCount, formatDate(updated))

        return ZStack(alignment: .bottomLeading) {
            Image(heroImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 260)
                .clipped()

            LinearGradient(
                colors: [
                    AppColors.brandBlueDark.opacity(0.15),
                    AppColors.brandBlueDark.opacity(0.65),
                    AppColors.brandWhite
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .frame(maxWidth: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandWhite)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppColors.brandWhite.opacity(0.9))
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)

                Button(AppStrings.profileViewMatches) {
                    onViewMatches()
                }
                .font(.headline)
                .foregroundStyle(AppColors.brandWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.brandBlueDark)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

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
                    Text(AppStrings.profileAiNone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                    Text(AppStrings.profileAiNone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.brandGreen)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(AppColors.brandBlueDark.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    TextEditor(text: $viewModel.draft.cvText)
                        .frame(minHeight: 140)
                        .disabled(true)
                }
            } label: {
                Text(AppStrings.profileSectionCv)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.9))
            }

            Button(AppStrings.profileUploadNewCv) {
                showUploadSheet = true
            }
            .font(.headline)
            .foregroundStyle(AppColors.brandWhite)
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

    private func normalizedRoles(_ roles: [String]?) -> [String] {
        guard let roles else { return [] }
        return roles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct ChipView: View {
    enum Style {
        case primary
        case secondary
    }

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

    var body: some View {
        FlowLayoutContainer(spacing: spacing) {
            content
        }
    }
}

private struct FlowLayoutContainer: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
            rowHeight = max(rowHeight, size.height)
        }

        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
