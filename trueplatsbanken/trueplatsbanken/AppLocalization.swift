import Foundation

enum AppLocalization {
    static var bundle: Bundle = .main

    static func localized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
}
