import SwiftUI

struct JobFiltersBar: View {
    let filters: JobFilterState
    let recentFilters: [JobFilterState]
    let onSelectRecent: (JobFilterState) -> Void
    let onClear: () -> Void
    let onOccupationTap: () -> Void
    let onLocationTap: () -> Void
    let onEmploymentTypeTap: () -> Void
    let onWorkingHoursTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(AppStrings.filtersTitle)
                    .font(.headline)
                Spacer()
                Menu {
                    if recentFilters.isEmpty {
                        Text(AppStrings.filterNoRecent)
                    } else {
                        ForEach(recentFilters, id: \.self) { filter in
                            Button(JobFilterPresentation.summary(for: filter)) {
                                onSelectRecent(filter)
                            }
                        }
                    }
                } label: {
                    Text(AppStrings.filtersRecent)
                        .font(.subheadline)
                }

                if !filters.isEmpty {
                    Button(AppStrings.filtersClear) {
                        onClear()
                    }
                    .font(.subheadline)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
