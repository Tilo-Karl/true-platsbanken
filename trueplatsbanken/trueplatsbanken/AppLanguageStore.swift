import Foundation

final class AppLanguageStore: ObservableObject {
    enum Language: String {
        case sv
        case en

        var localeIdentifier: String {
            switch self {
            case .sv:
                return "sv_SE"
            case .en:
                return "en_US"
            }
        }

        var bundleIdentifier: String {
            switch self {
            case .sv:
                return "sv"
            case .en:
                return "en"
            }
        }
    }

    @Published private(set) var language: Language

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    var buttonLabel: String {
        switch language {
        case .sv:
            return AppStrings.languageButtonSv
        case .en:
            return AppStrings.languageButtonEn
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        if let stored = userDefaults.string(forKey: "app.language"),
           let lang = Self.languageFromStoredValue(stored) {
            language = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en-US"
            language = preferred.hasPrefix("sv") ? .sv : .en
        }

        applyLanguage(userDefaults: userDefaults)
    }

    func toggle() {
        language = language == .sv ? .en : .sv
        applyLanguage(userDefaults: .standard)
    }

    private func applyLanguage(userDefaults: UserDefaults) {
        userDefaults.set(language.rawValue, forKey: "app.language")
        AppLocalization.bundle = bundleForLanguage(language)
    }

    private func bundleForLanguage(_ language: Language) -> Bundle {
        if let path = Bundle.main.path(forResource: language.bundleIdentifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    private static func languageFromStoredValue(_ value: String) -> Language? {
        if let language = Language(rawValue: value) {
            return language
        }
        if value == "en-US" || value == "en_US" {
            return .en
        }
        return nil
    }
}
