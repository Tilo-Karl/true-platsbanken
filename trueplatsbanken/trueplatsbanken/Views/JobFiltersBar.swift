import SwiftUI

struct JobFiltersBar: View {
    let filters: JobFilterState
    let onClear: () -> Void
    let onOccupationTap: () -> Void
    let onLocationTap: () -> Void
    let onEmploymentTypeTap: () -> Void
    let onWorkingHoursTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(AppStrings.appTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandGreen)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !filters.isEmpty {
                        JobFilterChip(
                            title: AppStrings.filtersClear,
                            value: "",
                            action: onClear,
                            isEmphasized: true
                        )
                    }
                    JobFilterChip(
                        title: AppStrings.filterOccupationTitle,
                        value: JobFilterPresentation.occupationLabel(for: filters),
                        action: onOccupationTap
                    )
                    JobFilterChip(
                        title: AppStrings.filterLocationTitle,
                        value: JobFilterPresentation.locationLabel(for: filters),
                        action: onLocationTap
                    )
                    JobFilterChip(
                        title: AppStrings.filterEmploymentTypeTitle,
                        value: JobFilterPresentation.employmentTypeLabel(for: filters),
                        action: onEmploymentTypeTap
                    )
                    JobFilterChip(
                        title: AppStrings.filterScopeTitle,
                        value: JobFilterPresentation.workingHoursLabel(for: filters),
                        action: onWorkingHoursTap
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}
