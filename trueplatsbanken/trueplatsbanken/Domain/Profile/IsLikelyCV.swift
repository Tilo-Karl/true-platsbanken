import Foundation

enum CVEligibility {
    static func isLikelyCV(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 800 else {
            return false
        }

        let yearCount = countYearTokens(in: trimmed)
        guard yearCount >= 2 else {
            return false
        }

        let sectionCount = countSectionKeywords(in: trimmed)
        return sectionCount >= 2
    }

    private static func countYearTokens(in text: String) -> Int {
        let pattern = "\\b(19|20)\\d{2}\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return 0
        }
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        return matches.count
    }

    private static func countSectionKeywords(in text: String) -> Int {
        let lowercased = text.lowercased()
        let keywords = [
            "experience",
            "work",
            "employment",
            "education",
            "skills",
            "projects",
            "summary",
            "profile",
            "certifications",
            "languages",
            "erfarenhet",
            "arbete",
            "anställning",
            "utbildning",
            "kompetenser",
            "projekt",
            "sammanfattning",
            "profil",
            "certifikat",
            "språk"
        ]

        var count = 0
        for keyword in keywords {
            if lowercased.contains(keyword) {
                count += 1
            }
        }
        return count
    }
}
