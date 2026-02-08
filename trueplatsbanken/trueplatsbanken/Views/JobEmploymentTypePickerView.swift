import SwiftUI

struct JobEmploymentTypePickerView: View {
    let employmentTypes: [TaxonomyItem]
    let selectedEmploymentType: TaxonomyItem?
    let onSelect: (TaxonomyItem?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button {
                onSelect(nil)
                dismiss()
            } label: {
                HStack {
                    Text(AppStrings.filterEmploymentTypeAny)
                    Spacer()
                    if selectedEmploymentType == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            ForEach(employmentTypes) { type in
                Button {
                    onSelect(type)
                    dismiss()
                } label: {
                    HStack {
                        Text(type.label)
                        Spacer()
                        if selectedEmploymentType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}
