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
        let localized = String(localized: key, locale: resolvedLocale)
        let languageCode = resolvedLocale.language.languageCode?.identifier
        guard languageCode == "de" else { return localized }

        let english = String(localized: key, locale: Locale(identifier: "en"))
        return germanFallbacks[english] ?? localized
    }

    private static let germanFallbacks: [String: String] = [
        "Add": "Hinzufügen",
        "Appearance": "Darstellung",
        "Avg. duration": "Ø Dauer",
        "Avg. rally": "Ø Ballwechsel",
        "Back": "Zurück",
        "Cancel Session": "Einheit abbrechen",
        "Date": "Datum",
        "Language": "Sprache",
        "Losses": "Niederlagen",
        "Lost": "Verloren",
        "Match Format": "Matchformat",
        "Match Setup": "Match vorbereiten",
        "Match Dynamics": "Match-Dynamik",
        "Notes": "Notizen",
        "Played": "Gespielt",
        "Settings": "Einstellungen",
        "Stats": "Statistik",
        "Streak": "Serie",
        "Start tracking before the first point. Your warmup counts too.": "Starte das Tracking schon vor dem ersten Punkt. Das Einspielen zählt mit.",
        "Start Warmup": "Einspielen starten",
        "Surfaces": "Beläge",
        "Theme": "Design",
        "Tracking is running": "Tracking läuft",
        "Unknown opponent": "Unbekannter Gegner",
        "Win rate": "Siegquote",
        "Win rate over time": "Siegquote im Verlauf",
        "Win rate trend": "Siegquoten-Trend",
        "Wins": "Siege",
        "Won": "Gewonnen"
    ]
}
