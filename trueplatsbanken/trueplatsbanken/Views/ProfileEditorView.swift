import SwiftUI
import UIKit

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let onSaved: () async -> Void
    @State private var showReplaceConfirmation = false

    var body: some View {
        let _ = languageStore.language

        NavigationStack {
            Form {
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
                        showReplaceConfirmation = true
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
                            await onSaved()
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
            }
            .navigationTitle(AppStrings.profileTitle)
            .confirmationDialog(
                AppStrings.profileReplaceConfirmTitle,
                isPresented: $showReplaceConfirmation
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
        }
    }
}
