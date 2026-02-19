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
    @State private var heroIndex = 0
    @State private var uploadError: String?

    private let heroImages = ["CVMatch7", "CVMatch8", "CVMatch9", "CVMatch10"]
    private let heroTimer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = languageStore.language

        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            Form {
                Section {
                    if isLiveMode {
                        aiSummaryCard()
                    } else {
                        heroCard()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section {
                    infoCard(
                        title: AppStrings.profileAiRoles,
                        value: rolesSummary(viewModel.aiResult?.roles)
                    )
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section {
                    infoCard(
                        title: AppStrings.profileAiInferredRoles,
                        value: rolesSummary(viewModel.aiResult?.inferredRoles)
                    )
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            showCvDetails.toggle()
                        } label: {
                            HStack {
                                Text(AppStrings.profileSectionCv)
                                    .font(.headline)
                                    .foregroundStyle(AppColors.brandBlack.opacity(0.9))
                                Spacer()
                                Image(systemName: showCvDetails ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if showCvDetails {
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
                    }
                    .padding(16)
                    .background(AppColors.brandWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

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
            .scrollContentBackground(.hidden)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Text(AppStrings.appTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandGreen)
                Spacer()
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
        .onReceive(heroTimer) { _ in
            guard !heroImages.isEmpty else { return }
            heroIndex = (heroIndex + 1) % heroImages.count
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

    private func heroBullet(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(AppColors.brandBlue.opacity(0.6))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func rolesSummary(_ roles: [String]?) -> String {
        guard let roles, !roles.isEmpty else {
            return AppStrings.profileAiNone
        }
        return roles.prefix(3).joined(separator: ", ")
    }

    private func heroCard() -> some View {
        VStack(spacing: 0) {
            Image(heroImages[heroIndex])
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                .clipped()
            VStack(spacing: 10) {
                Text(AppStrings.matchesOverlayTitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.9))
                    .multilineTextAlignment(.center)
                Text(AppStrings.matchesOverlaySubtitle)
                    .font(.footnote)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.6))
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 8) {
                    heroBullet(AppStrings.matchesOverlayBullet2)
                    heroBullet(AppStrings.matchesOverlayBullet3)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)

            Button {
                showUploadSheet = true
            } label: {
                Text(AppStrings.profileHeroUpload)
                    .font(.headline)
                    .foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(AppColors.brandWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        .padding(.vertical, 8)
    }

    private func aiSummaryCard() -> some View {
        let primaryRoles = rolesSummary(viewModel.aiResult?.roles)
        let updatedText = viewModel.lastUpdated.map { formatDate($0) }

        return VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.profileAiActive)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.brandGreen)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(AppColors.brandBlueDark.opacity(0.12))
                .clipShape(Capsule())

            Text(primaryRoles)
                .font(.headline)
                .foregroundStyle(AppColors.brandBlack.opacity(0.9))

            Text(AppStrings.profileMatchesFound(matchesCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let updatedText {
                Text(AppStrings.profileLastUpdated(updatedText))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

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

            Button(AppStrings.profileUploadNewCv) {
                showUploadSheet = true
            }
            .font(.subheadline)
            .foregroundStyle(AppColors.brandBlueDark)
        }
        .padding(16)
        .background(AppColors.brandWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        .padding(.vertical, 8)
    }

    private func infoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.brandBlack.opacity(0.9))
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(AppColors.brandWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
