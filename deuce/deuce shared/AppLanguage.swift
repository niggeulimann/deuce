import Foundation

enum AppLanguage {
    static func preferredLocale(from locale: Locale = .autoupdatingCurrent) -> Locale {
        locale.language.languageCode?.identifier == "de"
            ? Locale(identifier: "de")
            : Locale(identifier: "en")
    }
}

enum L10n {
    static func string(_ key: String.LocalizationValue) -> String {
        string(key, locale: AppLanguage.preferredLocale())
    }

    static func string(
        _ key: String.LocalizationValue,
        locale: Locale
    ) -> String {
        let resolvedLocale = AppLanguage.preferredLocale(from: locale)
        let languageCode = resolvedLocale.language.languageCode?.identifier ?? "en"

        // `String(localized:locale:)` only uses `locale:` for formatting — it
        // resolves the string-catalog table from the *bundle's* preferred
        // localization (i.e. the device language), not from the requested
        // locale. To genuinely force a language we look up the strings in that
        // language's `.lproj` sub-bundle.
        let bundle = localizedBundle(for: languageCode) ?? .main
        return String(localized: key, bundle: bundle, locale: resolvedLocale)
    }

    /// Returns the `.lproj` bundle for the given language code, falling back to
    /// English when the requested language isn't bundled. Cached per language.
    private static func localizedBundle(for languageCode: String) -> Bundle? {
        if let cached = bundleCache[languageCode] { return cached }

        let bundle = Bundle.main.path(forResource: languageCode, ofType: "lproj")
            .flatMap(Bundle.init(path:))
            ?? Bundle.main.path(forResource: "en", ofType: "lproj")
                .flatMap(Bundle.init(path:))

        bundleCache[languageCode] = bundle
        return bundle
    }

    nonisolated(unsafe) private static var bundleCache: [String: Bundle?] = [:]
}
