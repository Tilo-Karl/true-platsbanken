import Foundation

enum JobFiltering {
    static func apply(_ jobs: [Job], filters: JobFilterState) -> [Job] {
        guard !filters.isEmpty else {
            return jobs
        }

        return jobs.filter { job in
            matchesOccupation(job, filters: filters) &&
            matchesMunicipality(job, filters: filters) &&
            matchesEmploymentType(job, filters: filters) &&
            matchesWorkingHours(job, filters: filters)
        }
    }

    private static func matchesOccupation(_ job: Job, filters: JobFilterState) -> Bool {
        if !filters.occupations.isEmpty {
            return filters.occupations.contains { occupation in
                equalsLabel(job.occupationLabel, occupation.label)
            }
        }
        if let field = filters.occupationField?.label {
            return equalsLabel(job.occupationFieldLabel, field)
        }
        return true
    }

    private static func matchesMunicipality(_ job: Job, filters: JobFilterState) -> Bool {
        guard !filters.municipalities.isEmpty else {
            return true
        }
        return filters.municipalities.contains { municipality in
            equalsLabel(job.municipality, municipality.label)
        }
    }

    private static func matchesEmploymentType(_ job: Job, filters: JobFilterState) -> Bool {
        guard let filterLabel = filters.employmentType?.label else {
            return true
        }
        let jobLabel = nonEmpty(job.employmentTypeLabel) ?? job.employmentType
        return equalsLabel(jobLabel, filterLabel)
    }

    private static func matchesWorkingHours(_ job: Job, filters: JobFilterState) -> Bool {
        guard let filterLabel = filters.workingHoursType?.label else {
            return true
        }
        guard let jobLabel = nonEmpty(job.workingHoursTypeLabel) else {
            return false
        }
        return equalsLabel(jobLabel, filterLabel)
    }

    private static func equalsLabel(_ value: String?, _ target: String) -> Bool {
        let lhs = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let rhs = target.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lhs.isEmpty || rhs.isEmpty {
            return false
        }
        return lhs == rhs
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }
}
