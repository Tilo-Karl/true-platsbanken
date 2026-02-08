import SwiftUI

struct JobOccupationPickerView: View {
    let occupationFields: [TaxonomyItem]
    let occupations: [TaxonomyItem]
    let selectedField: TaxonomyItem?
    let selectedOccupations: [TaxonomyItem]
    let onSelectField: (TaxonomyItem) -> Void
    let onToggleOccupation: (TaxonomyItem) -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredOccupations: [TaxonomyItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return occupations
        }
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return occupations.filter { $0.label.lowercased().contains(normalized) }
    }

    private var bottomOccupationId: String? {
        filteredOccupations.last?.id
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField(AppStrings.filterSearchOccupations, text: $query)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .submitLabel(.search)
                                .onSubmit {
                                    guard let bottomId = bottomOccupationId else { return }
                                    withAnimation {
                                        proxy.scrollTo(bottomId, anchor: .bottom)
                                    }
                                }
                            if !query.isEmpty {
                                Button {
                                    query = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Section(AppStrings.filterFieldsTitle) {
                        ForEach(occupationFields) { field in
                            Button {
                                onSelectField(field)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(field.label)
                                    Spacer()
                                    if selectedField == field {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Section(AppStrings.filterOccupationsTitle) {
                        ForEach(filteredOccupations) { occupation in
                            Button {
                                onToggleOccupation(occupation)
                            } label: {
                                HStack {
                                    Text(occupation.label)
                                    Spacer()
                                    if selectedOccupations.contains(occupation) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(AppStrings.filterOccupationTitle)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(AppStrings.filtersClear) {
                            onClear()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(AppStrings.filterDone) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
