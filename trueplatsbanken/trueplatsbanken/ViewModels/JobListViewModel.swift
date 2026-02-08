import Foundation

@MainActor
final class JobListViewModel: ObservableObject {
    @Published private(set) var jobs: [Job] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var filters: JobFilterState = .empty {
        didSet {
            applyCurrentFilters()
        }
    }
    @Published private(set) var recentFilters: [JobFilterState] = []

    private let jobReader: JobReading
    private let recentStore: RecentJobFiltersReading & RecentJobFiltersWriting
    private var allJobs: [Job] = []

    init(
        jobReader: JobReading,
        recentStore: RecentJobFiltersReading & RecentJobFiltersWriting = RecentJobFiltersStore()
    ) {
        self.jobReader = jobReader
        self.recentStore = recentStore
        self.recentFilters = (try? recentStore.loadRecentFilters()) ?? []
    }

    func loadJobs() async {
        isLoading = true
        errorMessage = nil

        do {
            allJobs = try await jobReader.fetchJobs()
            applyCurrentFilters()
        } catch {
            errorMessage = error.localizedDescription
            allJobs = []
            jobs = []
        }

        isLoading = false
    }

    func updateFilters(_ newFilters: JobFilterState) {
        filters = newFilters
    }

    func clearFilters() {
        updateFilters(.empty)
    }

    func setOccupationField(_ field: TaxonomyItem?) {
        var updated = filters
        updated.occupationField = field
        if field != nil {
            updated.occupations = []
        }
        updateFilters(updated)
    }

    func toggleOccupation(_ occupation: TaxonomyItem) {
        var updated = filters
        if let index = updated.occupations.firstIndex(of: occupation) {
            updated.occupations.remove(at: index)
        } else {
            updated.occupations.append(occupation)
        }
        if !updated.occupations.isEmpty {
            updated.occupationField = nil
        }
        updateFilters(updated)
    }

    func clearOccupationFilters() {
        var updated = filters
        updated.occupations = []
        updated.occupationField = nil
        updateFilters(updated)
    }

    func setMunicipality(_ municipality: TaxonomyItem?) {
        var updated = filters
        updated.municipalities = municipality == nil ? [] : [municipality].compactMap { $0 }
        updateFilters(updated)
    }

    func toggleMunicipality(_ municipality: TaxonomyItem) {
        var updated = filters
        if let index = updated.municipalities.firstIndex(of: municipality) {
            updated.municipalities.remove(at: index)
        } else {
            updated.municipalities.append(municipality)
        }
        updateFilters(updated)
    }

    func clearMunicipalityFilters() {
        var updated = filters
        updated.municipalities = []
        updateFilters(updated)
    }

    func setEmploymentType(_ employmentType: TaxonomyItem?) {
        var updated = filters
        updated.employmentType = employmentType
        updateFilters(updated)
    }

    func setWorkingHoursType(_ workingHoursType: TaxonomyItem?) {
        var updated = filters
        updated.workingHoursType = workingHoursType
        updateFilters(updated)
    }

    func persistFiltersIfNeeded() {
        let updated = JobFilterHistory.updatedHistory(
            current: recentFilters,
            newFilter: filters,
            limit: 5
        )
        guard updated != recentFilters else { return }
        recentFilters = updated
        try? recentStore.saveRecentFilters(updated)
    }

    private func applyCurrentFilters() {
        jobs = JobFiltering.apply(allJobs, filters: filters)
    }
}
