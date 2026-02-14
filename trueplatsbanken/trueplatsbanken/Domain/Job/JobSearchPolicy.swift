import Foundation

struct JobSearchPolicy {
    let suggestionMinimumLength: Int = 2
    let fetchMinimumLength: Int = 3
    let suggestionLimit: Int = 5
    let recentSearchLimit: Int = 3

    func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func effectiveQuery(from query: String) -> String? {
        let normalizedQuery = normalized(query)
        return normalizedQuery.count >= fetchMinimumLength ? normalizedQuery : nil
    }

    func shouldFetchJobs(query: String, filtersEmpty: Bool) -> Bool {
        let normalizedQuery = normalized(query)
        if normalizedQuery.isEmpty {
            return true
        }
        if normalizedQuery.count >= fetchMinimumLength {
            return true
        }
        return !filtersEmpty
    }

    func shouldSuggest(query: String, lastCommittedQuery: String?) -> Bool {
        let normalizedQuery = normalized(query)
        if normalizedQuery.count < suggestionMinimumLength {
            return false
        }
        if let lastCommittedQuery, !lastCommittedQuery.isEmpty, normalizedQuery == lastCommittedQuery {
            return false
        }
        return true
    }

    func shouldShowRecentSearches(isFocused: Bool, query: String, recentSearches: [String]) -> Bool {
        guard isFocused else { return false }
        return normalized(query).count < fetchMinimumLength && !recentSearches.isEmpty
    }

    func shouldShowEmptySuggestions(
        isFocused: Bool,
        query: String,
        isSuggesting: Bool,
        suggestions: [String]
    ) -> Bool {
        guard isFocused else { return false }
        let normalizedQuery = normalized(query)
        return normalizedQuery.count >= suggestionMinimumLength && !isSuggesting && suggestions.isEmpty
    }

    func limitedSuggestions(_ suggestions: [String]) -> [String] {
        Array(suggestions.prefix(suggestionLimit))
    }

    func updatedRecentSearches(current: [String], newQuery: String) -> [String] {
        let normalizedQuery = normalized(newQuery)
        guard !normalizedQuery.isEmpty else { return current }
        var updated = current.filter { $0.caseInsensitiveCompare(normalizedQuery) != .orderedSame }
        updated.insert(normalizedQuery, at: 0)
        if updated.count > recentSearchLimit {
            updated = Array(updated.prefix(recentSearchLimit))
        }
        return updated
    }
}
