import Foundation

@MainActor
final class JobListViewModel: ObservableObject {
    @Published private(set) var jobs: [Job] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
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
    @Published private(set) var recentSearches: [String] = []
    @Published private(set) var isSuggesting = false

    private let jobReader: JobReading
    private let suggester: JobSuggesting
    private let policy: JobSearchPolicy
    private var filterTask: Task<Void, Never>?
    private var suggestionTask: Task<Void, Never>?
    private let debounceNanoseconds: UInt64 = 350_000_000
    private let suggestionDebounceNanoseconds: UInt64 = 250_000_000
    private var requestCounter: Int = 0
    private var lastCommittedQuery: String?
    private var nextCursor: String?
    private var lastSignature: String = ""
    private let recentSearchesStore: RecentSearchesReading & RecentSearchesWriting

    init(
        jobReader: JobReading,
        suggester: JobSuggesting = BackendJobSuggester(),
        recentSearchesStore: RecentSearchesReading & RecentSearchesWriting = RecentSearchesStore(),
        policy: JobSearchPolicy = JobSearchPolicy()
    ) {
        self.jobReader = jobReader
        self.suggester = suggester
        self.recentSearchesStore = recentSearchesStore
        self.policy = policy
        self.recentSearches = recentSearchesStore.loadRecentSearches()
    }

    var visibleSuggestions: [String] {
        policy.limitedSuggestions(searchSuggestions)
    }

    var hasSearchQuery: Bool {
        !policy.normalized(searchQuery).isEmpty
    }

    func shouldShowRecentSearches(isFocused: Bool) -> Bool {
        policy.shouldShowRecentSearches(
            isFocused: isFocused,
            query: searchQuery,
            recentSearches: recentSearches
        )
    }

    func shouldShowEmptySuggestions(isFocused: Bool) -> Bool {
        policy.shouldShowEmptySuggestions(
            isFocused: isFocused,
            query: searchQuery,
            isSuggesting: isSuggesting,
            suggestions: searchSuggestions
        )
    }

    func loadJobs() async {
        await fetchJobs(for: filters, showLoading: true)
    }

    func loadMoreIfNeeded(currentJob: Job) async {
        guard !isLoadingMore else { return }
        guard let lastJob = jobs.last, lastJob.id == currentJob.id else { return }
        guard let cursor = nextCursor else { return }
        await fetchNextPage(cursor: cursor)
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
        let normalizedQuery = policy.normalized(searchQuery)
        lastCommittedQuery = normalizedQuery.isEmpty ? nil : normalizedQuery
        if normalizedQuery.count >= policy.fetchMinimumLength {
            addRecentSearch(normalizedQuery)
        }
        clearSuggestions()
    }

    private func scheduleSuggestionFetch() {
        suggestionTask?.cancel()
        let normalizedQuery = policy.normalized(searchQuery)
        if !policy.shouldSuggest(query: searchQuery, lastCommittedQuery: lastCommittedQuery) {
            searchSuggestions = []
            return
        }
        suggestionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: suggestionDebounceNanoseconds)
            guard let self else { return }
            await self.fetchSuggestions(query: normalizedQuery)
        }
    }

    private func fetchSuggestions(query: String) async {
        isSuggesting = true
        do {
            let suggestions = try await suggester.fetchSuggestions(query: query, limit: policy.suggestionLimit)
            if query != policy.normalized(searchQuery) {
                isSuggesting = false
                return
            }
            let unique = Array(NSOrderedSet(array: suggestions)) as? [String] ?? suggestions
            searchSuggestions = Array(unique.prefix(policy.suggestionLimit))
        } catch {
            searchSuggestions = []
        }
        isSuggesting = false
    }

    private func fetchJobs(for filters: JobFilterState, showLoading: Bool) async {
        requestCounter += 1
        let requestId = requestCounter
        let effectiveQuery = policy.effectiveQuery(from: searchQuery)
        if !policy.shouldFetchJobs(query: searchQuery, filtersEmpty: filters.isEmpty) {
            return
        }
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        nextCursor = nil
        isLoadingMore = false

        do {
            let queryFilters: JobFilterState? = filters.isEmpty ? nil : filters
            let fetched = try await jobReader.fetchJobs(filters: queryFilters, query: effectiveQuery, cursor: nil)
            if requestId != requestCounter {
                return
            }
            jobs = fetched.jobs
            nextCursor = fetched.nextCursor
            lastSignature = signature(for: filters, query: effectiveQuery)
        } catch {
            errorMessage = error.localizedDescription
            jobs = []
        }

        if showLoading {
            isLoading = false
        }
    }

    private func fetchNextPage(cursor: String) async {
        guard !isLoadingMore else { return }
        let effectiveQuery = policy.effectiveQuery(from: searchQuery)
        let signature = signature(for: filters, query: effectiveQuery)
        guard signature == lastSignature else { return }

        isLoadingMore = true
        do {
            let queryFilters: JobFilterState? = filters.isEmpty ? nil : filters
            let fetched = try await jobReader.fetchJobs(filters: queryFilters, query: effectiveQuery, cursor: cursor)
            if signature != lastSignature {
                isLoadingMore = false
                return
            }
            jobs.append(contentsOf: fetched.jobs)
            nextCursor = fetched.nextCursor
        } catch {
            nextCursor = nil
        }
        isLoadingMore = false
    }

    private func signature(for filters: JobFilterState, query: String?) -> String {
        let queryValue = query ?? ""
        return "\(queryValue)|\(filters.hashValue)"
    }

    private func addRecentSearch(_ query: String) {
        let updated = policy.updatedRecentSearches(current: recentSearches, newQuery: query)
        recentSearches = updated
        recentSearchesStore.saveRecentSearches(updated)
    }
}
