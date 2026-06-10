import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    static let storageKey = "appLanguage"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }

    var label: String {
        switch self {
        case .german: "Deutsch"
        case .english: "English"
        }
    }

    static var systemDefault: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("de") == true ? .german : .english
    }

    static var selected: AppLanguage {
        guard let rawValue = UserDefaults.standard.string(forKey: storageKey) else {
            return systemDefault
        }
        return AppLanguage(rawValue: rawValue) ?? systemDefault
    }
}

enum L10n {
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: AppLanguage.selected.locale)
    }
}
