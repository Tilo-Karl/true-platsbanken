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

    var body: some View {
        NavigationStack {
            List {
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
