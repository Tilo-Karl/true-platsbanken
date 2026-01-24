import Foundation

enum JobDateParsing {
    static var stockholmTimeZone: TimeZone {
        TimeZone(identifier: "Europe/Stockholm") ?? .current
    }

    static var stockholmCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = stockholmTimeZone
        return calendar
    }

    static func parsePublicationDate(_ value: String?) -> Date? {
        guard let value else {
            return nil
        }

        if let date = parseISO8601(value) {
            return date
        }

        return parseStockholmLocal(value, timeZone: stockholmTimeZone)
    }

    static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        return fallback.date(from: value)
    }

    private static func parseStockholmLocal(_ value: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: value)
    }
}
