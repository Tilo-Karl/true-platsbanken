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
    static var jobsSearchPlaceholder: String { localized("jobs.search.placeholder") }
    static var searchSuggestionsNone: String { localized("jobs.search.suggestions.none") }
    static var searchRecentTitle: String { localized("jobs.search.recent.title") }

    static var matchesLoading: String { localized("matches.loading") }
    static var matchesLoadingLive: String { localized("matches.loading.live") }
    static var matchesUnavailable: String { localized("matches.unavailable") }
    static var noMatches: String { localized("matches.none") }
    static var refreshToCheck: String { localized("matches.refreshToCheck") }
    static var refresh: String { localized("common.refresh") }
    static var filtersTitle: String { localized("filters.title") }
    static var appTitle: String { localized("app.title") }
    static var filtersClear: String { localized("filters.clear") }
    static var filterOccupationTitle: String { localized("filters.occupation.title") }
    static var filterOccupationAny: String { localized("filters.occupation.any") }
    static var filterLocationTitle: String { localized("filters.location.title") }
    static var filterLocationAny: String { localized("filters.location.any") }
    static func filterLocationMultiple(_ count: Int) -> String {
        String(format: localized("filters.location.multiple"), locale: Locale.current, count)
    }
    static var filterEmploymentTypeTitle: String { localized("filters.employmentType.title") }
    static var filterEmploymentTypeAny: String { localized("filters.employmentType.any") }
    static var filterScopeTitle: String { localized("filters.scope.title") }
    static var filterScopeAny: String { localized("filters.scope.any") }
    static func filterOccupationMultiple(_ count: Int) -> String {
        String(format: localized("filters.occupation.multiple"), locale: Locale.current, count)
    }
    static var filterFieldsTitle: String { localized("filters.fields.title") }
    static var filterOccupationsTitle: String { localized("filters.occupations.title") }
    static var filterLocationsTitle: String { localized("filters.locations.title") }
    static var filterSearchOccupations: String { localized("filters.occupations.search") }
    static var filterSearchLocations: String { localized("filters.locations.search") }
    static var filterSummaryAny: String { localized("filters.summary.any") }
    static var filterSummarySeparator: String { localized("filters.summary.separator") }
    static var filterLoading: String { localized("filters.loading") }
    static var filterDone: String { localized("filters.done") }

    static func scoreLabel(_ score: Int) -> String {
        String(format: localized("matches.score"), locale: Locale.current, score)
    }
    static var matchesDemoBadge: String { localized("matches.demoBadge") }
    static var matchesOverlayTitle: String { localized("matches.overlay.title") }
    static var matchesOverlayUploadPhoto: String { localized("matches.overlay.uploadPhoto") }
    static var matchesOverlayUploadFile: String { localized("matches.overlay.uploadFile") }
    static var matchesOverlayBullet1: String { localized("matches.overlay.bullet1") }
    static var matchesOverlayBullet2: String { localized("matches.overlay.bullet2") }
    static var matchesOverlayBullet3: String { localized("matches.overlay.bullet3") }
    static var matchesOverlaySubtitle: String { localized("matches.overlay.subtitle") }
    static var uploadEmptyError: String { localized("upload.error.empty") }
    static var uploadTooLargeError: String { localized("upload.error.tooLarge") }
    static func uploadSuccessPhotos(_ count: Int) -> String {
        let key = count == 1 ? "upload.success.photos.one" : "upload.success.photos.other"
        return String(format: localized(key), locale: Locale.current, count)
    }
    static func uploadSuccessFiles(_ count: Int) -> String {
        let key = count == 1 ? "upload.success.files.one" : "upload.success.files.other"
        return String(format: localized(key), locale: Locale.current, count)
    }
    static var paymentTitle: String { localized("payment.title") }
    static var paymentSubtitle: String { localized("payment.subtitle") }
    static var paymentContinue: String { localized("payment.continue") }
    static var paymentCancel: String { localized("payment.cancel") }
    static var processingTitle: String { localized("processing.title") }
    static var processingSubtitle: String { localized("processing.subtitle") }
    static var failureTitle: String { localized("failure.title") }
    static var failureBody: String { localized("failure.body") }
    static var failureRetry: String { localized("failure.retry") }

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
    static var profileImportPhotos: String { localized("profile.action.importPhotos") }
    static var profileImportFiles: String { localized("profile.action.importFiles") }
    static var profileImportNoInput: String { localized("profile.import.noInput") }
    static var profileImportNoText: String { localized("profile.import.noText") }
    static var profileImportFailed: String { localized("profile.import.failed") }
    static var profileCvRejected: String { localized("profile.cv.rejected") }
    static var profileAiSummary: String { localized("profile.ai.summary") }
    static var profileAiSeniority: String { localized("profile.ai.seniority") }
    static var profileAiLocations: String { localized("profile.ai.locations") }
    static var profileAiRoles: String { localized("profile.ai.roles") }
    static var profileAiInferredRoles: String { localized("profile.ai.inferredRoles") }
    static var profileAiKeywords: String { localized("profile.ai.keywords") }
    static var profileAiNone: String { localized("profile.ai.none") }
    static var profileLocationPreference: String { localized("profile.field.locationPreference") }
    static var profileDemoCvBadge: String { localized("profile.demoCvBadge") }
    static func profileRunMatch(_ price: String) -> String {
        String(format: localized("profile.action.runMatch"), locale: Locale.current, price)
    }
    static var profileHeroUpload: String { localized("profile.hero.upload") }
    static var profileUploadNewCv: String { localized("profile.upload.newCv") }
    static var profileAiActive: String { localized("profile.ai.active") }
    static func profileLastUpdated(_ value: String) -> String {
        String(format: localized("profile.lastUpdated"), locale: Locale.current, value)
    }
    static func profileMatchesFound(_ count: Int) -> String {
        String(format: localized("profile.matchesFound"), locale: Locale.current, count)
    }
    static var profileViewMatches: String { localized("profile.viewMatches") }
    static var profileDetailsTitle: String { localized("profile.details.title") }

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
        let key = count == 1 ? "jobs.vacanciesLabel.one" : "jobs.vacanciesLabel.other"
        return String(format: localized(key), locale: Locale.current, count)
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
        let key = days == 1 ? "jobs.applicationDeadlineWithDays.one" : "jobs.applicationDeadlineWithDays.other"
        return String(format: localized(key), locale: Locale.current, date, days)
    }

    static var viewListing: String { localized("jobs.viewListing") }
    static var unknownLabel: String { localized("common.unknown") }

    static var languageButtonSv: String { localized("language.button.sv") }
    static var languageButtonEn: String { localized("language.button.en") }

    static var shareTitle: String { localized("share.title") }
    static var shareSubtitle: String { localized("share.subtitle") }
    static var shareProcessing: String { localized("share.processing") }
    static var shareDone: String { localized("share.done") }
    static var shareError: String { localized("share.error") }
    static var shareOpenApp: String { localized("share.openApp") }
    static var shareClose: String { localized("share.close") }
    static var shareLimit: String { localized("share.limit") }
}
