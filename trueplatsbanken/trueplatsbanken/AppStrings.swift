import Foundation

enum AppStrings {
    private static func localized(_ key: String) -> String {
        AppLocalization.localized(key)
    }

    static var jobsTitle: String { localized("jobs.title") }
    static var matchesTitle: String { localized("matches.title") }
    static var profileTitle: String { localized("profile.title") }
    static var jobDetailTitle: String { localized("jobDetail.title") }

    static var jobsLoading: String { localized("jobs.loading") }
    static var jobsUnavailable: String { localized("jobs.unavailable") }
    static var noJobs: String { localized("jobs.none") }
    static var checkBackLater: String { localized("jobs.checkBackLater") }

    static var matchesLoading: String { localized("matches.loading") }
    static var matchesUnavailable: String { localized("matches.unavailable") }
    static var noMatches: String { localized("matches.none") }
    static var refreshToCheck: String { localized("matches.refreshToCheck") }
    static var refresh: String { localized("common.refresh") }

    static func scoreLabel(_ score: Int) -> String {
        String(format: localized("matches.score"), locale: Locale.current, score)
    }

    static var profileSectionIdentity: String { localized("profile.section.identity") }
    static var profileSectionPreferences: String { localized("profile.section.preferences") }
    static var profileSectionSkills: String { localized("profile.section.skills") }
    static var profileSectionCv: String { localized("profile.section.cv") }
    static var profileUserId: String { localized("profile.field.userId") }
    static var profileName: String { localized("profile.field.name") }
    static var profileEmail: String { localized("profile.field.email") }
    static var profilePhone: String { localized("profile.field.phone") }
    static var profileMunicipality: String { localized("profile.field.municipality") }
    static var profileEmploymentType: String { localized("profile.field.employmentType") }
    static var profileSkillsPlaceholder: String { localized("profile.field.skillsPlaceholder") }
    static var saveProfile: String { localized("profile.action.save") }
    static var profileExtract: String { localized("profile.action.extract") }
    static var profilePasteCv: String { localized("profile.action.pasteCv") }
    static var profileReplaceCv: String { localized("profile.action.replaceCv") }
    static var profileReplaceConfirmTitle: String { localized("profile.replace.title") }
    static var profileReplaceConfirmMessage: String { localized("profile.replace.message") }
    static var profileReplaceConfirmAction: String { localized("profile.replace.confirm") }
    static var profileReplaceCancel: String { localized("profile.replace.cancel") }
    static var profileMatch: String { localized("profile.action.match") }
    static var profileAiSummary: String { localized("profile.ai.summary") }
    static var profileAiSeniority: String { localized("profile.ai.seniority") }
    static var profileAiLocations: String { localized("profile.ai.locations") }
    static var profileAiRoles: String { localized("profile.ai.roles") }
    static var profileAiInferredRoles: String { localized("profile.ai.inferredRoles") }
    static var profileAiKeywords: String { localized("profile.ai.keywords") }
    static var profileAiNone: String { localized("profile.ai.none") }

    static func employmentTypeLabel(for key: String) -> String {
        switch key {
        case "any":
            return localized("employmentType.any")
        case "full_time":
            return localized("employmentType.fullTime")
        case "part_time":
            return localized("employmentType.partTime")
        case "contract":
            return localized("employmentType.contract")
        default:
            return key.replacingOccurrences(of: "_", with: " ")
        }
    }

    static func headlineWithVacancies(_ title: String, _ count: Int) -> String {
        String(format: localized("jobs.headlineWithVacancies"), locale: Locale.current, title, count)
    }

    static func vacanciesLabel(_ count: Int) -> String {
        String(format: localized("jobs.vacanciesLabel"), locale: Locale.current, count)
    }

    static func employerLine(workplace: String, municipality: String) -> String {
        String(format: localized("jobs.employerLine"), locale: Locale.current, workplace, municipality)
    }

    static func scopeOfWorkSinglePercent(_ value: Int) -> String {
        String(format: localized("jobs.scopeOfWork.single"), locale: Locale.current, value)
    }

    static func scopeOfWorkRangePercent(min: Int, max: Int) -> String {
        String(format: localized("jobs.scopeOfWork.range"), locale: Locale.current, min, max)
    }

    static var newBadge: String { localized("jobs.badge.new") }
    static func publishedToday(_ time: String) -> String {
        String(format: localized("jobs.publishedToday"), locale: Locale.current, time)
    }
    static func publishedOn(_ date: String) -> String {
        String(format: localized("jobs.publishedOn"), locale: Locale.current, date)
    }

    static func applicationDeadline(_ date: String) -> String {
        String(format: localized("jobs.applicationDeadline"), locale: Locale.current, date)
    }

    static func applicationDeadline(_ date: String, days: Int) -> String {
        String(format: localized("jobs.applicationDeadlineWithDays"), locale: Locale.current, date, days)
    }

    static var viewListing: String { localized("jobs.viewListing") }
    static var unknownLabel: String { localized("common.unknown") }

    static var languageButtonSv: String { localized("language.button.sv") }
    static var languageButtonEn: String { localized("language.button.en") }
}
