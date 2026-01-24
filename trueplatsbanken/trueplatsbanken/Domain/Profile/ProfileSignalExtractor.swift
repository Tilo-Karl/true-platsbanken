import Foundation

struct ProfileSignalExtractor {
    static func extract(
        skillsText: String?,
        cvText: String?,
        employmentPreferences: EmploymentPreferences
    ) -> ProfileSignals {
        let skillsTokens = tokenize(skillsText)
        let cvTokens = tokenize(cvText)
        let keywords = uniquePreservingOrder(skillsTokens + cvTokens)

        let occupations = uniquePreservingOrder(
            extractLabeledValues(from: skillsText, labels: ["occupation:", "role:", "yrke:", "roll:"]) +
            extractLabeledValues(from: cvText, labels: ["occupation:", "role:", "yrke:", "roll:"])
        )

        var locationValues: [String] = []
        if let preferredLocation = normalizeLocation(employmentPreferences.municipality) {
            locationValues.append(preferredLocation)
        }
        locationValues.append(contentsOf: extractLabeledValues(from: skillsText, labels: ["location:", "ort:", "plats:", "stad:"]))
        locationValues.append(contentsOf: extractLabeledValues(from: cvText, labels: ["location:", "ort:", "plats:", "stad:"]))
        let locations = uniquePreservingOrder(locationValues)

        let seniorityHints = uniquePreservingOrder(
            extractSeniorityHints(from: skillsText) + extractSeniorityHints(from: cvText)
        )

        let employmentType = normalizeEmploymentType(employmentPreferences.employmentType)
        let constraints = Constraints(
            employmentType: employmentType,
            locations: locations
        )

        return ProfileSignals(
            keywords: keywords,
            occupations: occupations,
            locations: locations,
            seniorityHints: seniorityHints,
            constraints: constraints
        )
    }

    private static func normalizeEmploymentType(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "any" {
            return nil
        }
        return trimmed
    }

    private static func tokenize(_ text: String?) -> [String] {
        guard let text else { return [] }
        let lowercased = text.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let parts = lowercased.components(separatedBy: separators)
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }
    }

    private static func extractLabeledValues(from text: String?, labels: [String]) -> [String] {
        guard let text else { return [] }
        let lines = text.components(separatedBy: .newlines)
        var results: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            for label in labels {
                if lower.hasPrefix(label) {
                    let value = trimmed.dropFirst(label.count).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        results.append(value)
                    }
                }
            }
        }
        return results
    }

    private static func extractSeniorityHints(from text: String?) -> [String] {
        let tokens = tokenize(text)
        let hints = [
            "junior",
            "senior",
            "lead",
            "principal",
            "staff",
            "manager",
            "chef",
            "ansvarig"
        ]
        var results: [String] = []
        for hint in hints {
            if tokens.contains(hint) {
                results.append(hint)
            }
        }
        return results
    }

    private static func normalizeLocation(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        return trimmed
    }

    private static func uniquePreservingOrder(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values {
            let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty || seen.contains(key) {
                continue
            }
            seen.insert(key)
            result.append(key)
        }
        return result
    }
}
