import SwiftUI

struct JobLocationPickerView: View {
    let municipalities: [TaxonomyItem]
    let selectedMunicipalities: [TaxonomyItem]
    let onToggle: (TaxonomyItem) -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private let searchPolicy = TaxonomySearchPolicy()

    private var filteredMunicipalities: [TaxonomyItem] {
        searchPolicy.filter(items: municipalities, query: query)
    }

    private var bottomMunicipalityId: String? {
        filteredMunicipalities.last?.id
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField(AppStrings.filterSearchLocations, text: $query)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .submitLabel(.search)
                                .onSubmit {
                                    guard let bottomId = bottomMunicipalityId else { return }
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

                    ForEach(filteredMunicipalities) { municipality in
                        Button {
                            onToggle(municipality)
                        } label: {
                            HStack {
                                Text(municipality.label)
                                Spacer()
                                if selectedMunicipalities.contains(municipality) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                .navigationTitle(AppStrings.filterLocationTitle)
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
