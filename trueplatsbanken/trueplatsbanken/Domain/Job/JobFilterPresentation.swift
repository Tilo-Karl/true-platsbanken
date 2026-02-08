import Foundation

enum JobFilterPresentation {
    static func occupationLabel(for filters: JobFilterState) -> String {
        if !filters.occupations.isEmpty {
            if filters.occupations.count == 1, let label = filters.occupations.first?.label {
                return label
            }
            return AppStrings.filterOccupationMultiple(filters.occupations.count)
        }
        if let field = filters.occupationField?.label {
            return field
        }
        return AppStrings.filterOccupationAny
    }

    static func locationLabel(for filters: JobFilterState) -> String {
        if !filters.municipalities.isEmpty {
            if filters.municipalities.count == 1, let label = filters.municipalities.first?.label {
                return label
            }
            return AppStrings.filterLocationMultiple(filters.municipalities.count)
        }
        return AppStrings.filterLocationAny
    }

    static func employmentTypeLabel(for filters: JobFilterState) -> String {
        if let employmentType = filters.employmentType?.label {
            return employmentType
        }
        return AppStrings.filterEmploymentTypeAny
    }

    static func workingHoursLabel(for filters: JobFilterState) -> String {
        if let workingHoursType = filters.workingHoursType?.label {
            return workingHoursType
        }
        return AppStrings.filterScopeAny
    }

    static func summary(for filters: JobFilterState) -> String {
        let parts = [
            occupationLabel(for: filters),
            locationLabel(for: filters),
            employmentTypeLabel(for: filters),
            workingHoursLabel(for: filters)
        ].filter { !$0.isEmpty && $0 != AppStrings.filterOccupationAny && $0 != AppStrings.filterLocationAny && $0 != AppStrings.filterEmploymentTypeAny && $0 != AppStrings.filterScopeAny }

        if parts.isEmpty {
            return AppStrings.filterSummaryAny
        }
        return parts.joined(separator: AppStrings.filterSummarySeparator)
    }
}
