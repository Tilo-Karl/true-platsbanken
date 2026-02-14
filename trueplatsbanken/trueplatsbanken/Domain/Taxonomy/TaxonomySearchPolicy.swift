import Foundation

struct TaxonomySearchPolicy {
    func filter(items: [TaxonomyItem], query: String) -> [TaxonomyItem] {
        let normalized = normalizedQuery(query)
        guard !normalized.isEmpty else {
            return items
        }
        return items.filter { item in
            item.label.lowercased().contains(normalized)
        }
    }

    private func normalizedQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
