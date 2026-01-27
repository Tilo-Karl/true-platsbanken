import Foundation

struct BackendServiceURLProvider {
    static func baseURL() -> URL {
        let value = "https://true-platsbanken-185847335768.europe-north1.run.app"
        guard let url = URL(string: value) else {
            preconditionFailure("BackendBaseURL is not a valid URL.")
        }
        return url
    }
}
