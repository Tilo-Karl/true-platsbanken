import Foundation

enum JobPresentation {
    struct PublishedPresentation {
        let listLabel: String
        let badgeLabel: String?
        let dateLabel: String
    }

    static func headline(for job: Job) -> String {
        if let vacancies = job.numberOfVacancies {
            let count = Int(vacancies)
            if count > 1 {
                return AppStrings.headlineWithVacancies(job.title, count)
            }
        }
        return job.title
    }

    static func employerLine(for job: Job) -> String {
        if let workplace = nonEmpty(job.employerWorkplace) {
            return workplaceLine(workplace, municipality: job.municipality)
        }
        return workplaceLine(job.employerName, municipality: job.municipality)
    }

    static func employmentTypeLabel(for job: Job) -> String {
        if let label = nonEmpty(job.employmentTypeLabel) {
            return label
        }

        let value = job.employmentType.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return AppStrings.unknownLabel
        }

        return AppStrings.employmentTypeLabel(for: value)
    }

    static func scopeOfWorkLabel(for job: Job) -> String? {
        if let label = nonEmpty(job.scopeOfWorkLabel) {
            return label
        }

        if let scope = job.scopeOfWork,
           let min = scope.min,
           let max = scope.max {
            if min == max {
                return AppStrings.scopeOfWorkSinglePercent(Int(min))
            }
            return AppStrings.scopeOfWorkRangePercent(min: Int(min), max: Int(max))
        }

        return nil
    }

    static func occupationLabel(for job: Job) -> String? {
        nonEmpty(job.occupationLabel)
    }

    static func vacanciesLabel(for job: Job) -> String? {
        guard let vacancies = job.numberOfVacancies else {
            return nil
        }
        let count = Int(vacancies)
        if count == 0 {
            return nil
        }
        return AppStrings.vacanciesLabel(count)
    }

    static func applicationDeadlineLabel(for job: Job) -> String? {
        guard let value = nonEmpty(job.applicationDeadline) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateFormat = "yyyy-MM-dd"

        if let date = JobDateParsing.parseISO8601(value) {
            let base = formatter.string(from: date)
            if let days = daysUntil(date), days >= 0 {
                return AppStrings.applicationDeadline(base, days: days)
            }
            return AppStrings.applicationDeadline(base)
        }

        return AppStrings.applicationDeadline(value)
    }

    static func publishedPresentation(for job: Job, now: Date) -> PublishedPresentation? {
        guard let date = job.publishedAt else {
            return nil
        }

        let calendar = JobDateParsing.stockholmCalendar
        let dateFormatter = stockholmDateFormatter()
        let timeFormatter = stockholmTimeFormatter()
        let isToday = calendar.isDate(date, inSameDayAs: now)

        let listLabel: String
        let badgeLabel: String?

        if isToday {
            listLabel = AppStrings.publishedToday(timeFormatter.string(from: date))
            badgeLabel = AppStrings.newBadge
        } else {
            listLabel = AppStrings.publishedOn(dateFormatter.string(from: date))
            badgeLabel = nil
        }

        return PublishedPresentation(
            listLabel: listLabel,
            badgeLabel: badgeLabel,
            dateLabel: dateFormatter.string(from: date)
        )
    }

    static func publishedDateLabel(for job: Job) -> String? {
        guard let date = job.publishedAt else {
            return nil
        }
        let formatter = stockholmDateFormatter()
        return formatter.string(from: date)
    }

    private static func workplaceLine(_ workplace: String, municipality: String) -> String {
        let trimmed = municipality.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return workplace
        }
        return AppStrings.employerLine(workplace: workplace, municipality: trimmed)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }

    private static func daysUntil(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    private static func stockholmDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.timeZone = JobDateParsing.stockholmTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func stockholmTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.timeZone = JobDateParsing.stockholmTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}
