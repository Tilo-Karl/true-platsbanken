import Foundation

@MainActor
final class JobListViewModel: ObservableObject {
    @Published private(set) var jobs: [Job] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var filters: JobFilterState = .empty {
        didSet {
            scheduleFilteredFetch()
        }
    }
    @Published var searchQuery: String = "" {
        didSet {
            scheduleFilteredFetch()
            scheduleSuggestionFetch()
        }
    }
    @Published private(set) var searchSuggestions: [String] = []
    @Published private(set) var recentFilters: [JobFilterState] = []

    private let jobReader: JobReading
    private let suggester: JobSuggesting
    private let recentStore: RecentJobFiltersReading & RecentJobFiltersWriting
    private var filterTask: Task<Void, Never>?
    private var suggestionTask: Task<Void, Never>?
    private let debounceNanoseconds: UInt64 = 350_000_000
    private let suggestionDebounceNanoseconds: UInt64 = 250_000_000
    private let suggestionLimit: Int = 5
    private var requestCounter: Int = 0
    private var lastCommittedQuery: String?

    init(
        jobReader: JobReading,
        recentStore: RecentJobFiltersReading & RecentJobFiltersWriting = RecentJobFiltersStore(),
        suggester: JobSuggesting = BackendJobSuggester()
    ) {
        self.jobReader = jobReader
        self.recentStore = recentStore
        self.suggester = suggester
        self.recentFilters = (try? recentStore.loadRecentFilters()) ?? []
    }

    func loadJobs() async {
        await fetchJobs(for: filters, showLoading: true)
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

    private func scheduleFilteredFetch() {
        filterTask?.cancel()
        let snapshot = filters
        filterTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard let self else { return }
            await self.fetchJobs(for: snapshot, showLoading: false)
        }
    }

    func clearSuggestions() {
        searchSuggestions = []
    }

    func commitSearchQuery() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        lastCommittedQuery = trimmed.isEmpty ? nil : trimmed
        clearSuggestions()
    }

    private func scheduleSuggestionFetch() {
        suggestionTask?.cancel()
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lastCommittedQuery, !lastCommittedQuery.isEmpty, query == lastCommittedQuery {
            searchSuggestions = []
            return
        }
        if query.count < 2 {
            searchSuggestions = []
            return
        }
        suggestionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: suggestionDebounceNanoseconds)
            guard let self else { return }
            await self.fetchSuggestions(query: query)
        }
    }

    private func fetchSuggestions(query: String) async {
        do {
            let suggestions = try await suggester.fetchSuggestions(query: query, limit: suggestionLimit)
            if query != searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) {
                return
            }
            let unique = Array(NSOrderedSet(array: suggestions)) as? [String] ?? suggestions
            searchSuggestions = Array(unique.prefix(suggestionLimit))
        } catch {
            searchSuggestions = []
        }
    }

    private func fetchJobs(for filters: JobFilterState, showLoading: Bool) async {
        requestCounter += 1
        let requestId = requestCounter
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveQuery = trimmedQuery.count >= 3 ? trimmedQuery : nil
        print("[jobs] fetch start", requestId, "filters empty:", filters.isEmpty, "query:", effectiveQuery ?? "nil")
        if effectiveQuery == nil && !trimmedQuery.isEmpty && filters.isEmpty {
            print("[jobs] skip fetch for short query", requestId)
            return
        }
        if showLoading {
            isLoading = true
        }
        errorMessage = nil

        do {
            let queryFilters: JobFilterState? = filters.isEmpty ? nil : filters
            let fetched = try await jobReader.fetchJobs(filters: queryFilters, query: effectiveQuery)
            if requestId != requestCounter {
                print("[jobs] stale response ignored", requestId)
                return
            }
            jobs = fetched
        } catch {
            errorMessage = error.localizedDescription
            jobs = []
        }

        if showLoading {
            isLoading = false
        }
        print("[jobs] fetch done", requestId, "count:", jobs.count)
    }
}
