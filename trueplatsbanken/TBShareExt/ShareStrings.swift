import Foundation

enum ShareStrings {
    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    static var title: String { localized("share.title") }
    static var subtitle: String { localized("share.subtitle") }
    static var processing: String { localized("share.processing") }
    static var done: String { localized("share.done") }
    static var error: String { localized("share.error") }
    static var openApp: String { localized("share.openApp") }
    static var close: String { localized("share.close") }
    static var limit: String { localized("share.limit") }
}
