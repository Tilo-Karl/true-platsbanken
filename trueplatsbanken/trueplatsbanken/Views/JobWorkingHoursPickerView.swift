import SwiftUI

struct JobWorkingHoursPickerView: View {
    let workingHoursTypes: [TaxonomyItem]
    let selectedWorkingHoursType: TaxonomyItem?
    let onSelect: (TaxonomyItem?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button {
                onSelect(nil)
                dismiss()
            } label: {
                HStack {
                    Text(AppStrings.filterScopeAny)
                    Spacer()
                    if selectedWorkingHoursType == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            ForEach(workingHoursTypes) { type in
                Button {
                    onSelect(type)
                    dismiss()
                } label: {
                    HStack {
                        Text(type.label)
                        Spacer()
                        if selectedWorkingHoursType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}
