import Foundation

struct BackendServiceURLProvider {
    static func baseURL() -> URL {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String else {
            preconditionFailure("BackendBaseURL is missing from Info.plist.")
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            preconditionFailure("BackendBaseURL is empty.")
        }

        guard trimmed.contains("://") else {
            preconditionFailure("BackendBaseURL must include a URL scheme (https://).")
        }

        guard let url = URL(string: trimmed) else {
            preconditionFailure("BackendBaseURL is not a valid URL.")
        }

        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            preconditionFailure("BackendBaseURL must use https.")
        }

        if let host = url.host?.lowercased(), host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0" {
            preconditionFailure("BackendBaseURL must not use localhost. Use a reachable HTTPS URL.")
        }

        return url
    }
}
