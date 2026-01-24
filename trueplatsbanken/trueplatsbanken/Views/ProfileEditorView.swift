import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onSaved: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("User ID", text: $viewModel.draft.userId)
                        .textInputAutocapitalization(.never)
                    TextField("Name", text: $viewModel.draft.name)
                    TextField("Email", text: $viewModel.draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $viewModel.draft.phone)
                        .keyboardType(.phonePad)
                }

                Section("Preferences") {
                    TextField("Municipality", text: $viewModel.draft.municipality)
                    Picker("Employment Type", selection: $viewModel.draft.employmentType) {
                        ForEach(EmploymentTypeOptions.all, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " "))
                        }
                    }
                }

                Section("Skills") {
                    TextField("Comma-separated skills", text: $viewModel.draft.skillsText)
                }

                Section("CV") {
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
                            Text("Save Profile")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
