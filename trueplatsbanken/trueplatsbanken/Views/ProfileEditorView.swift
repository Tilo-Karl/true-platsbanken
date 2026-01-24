import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let onSaved: () async -> Void

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

                Section(AppStrings.profileSectionCv) {
                    TextEditor(text: $viewModel.draft.cvText)
                        .frame(minHeight: 120)
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
                            await viewModel.saveProfile()
                            await onSaved()
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
        }
    }
}
