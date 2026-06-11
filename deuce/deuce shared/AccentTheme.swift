import SwiftUI

enum AccentTheme: String, CaseIterable, Identifiable {
    case green, blue, orange, purple, white

    var id: String { rawValue }

    var label: String {
        label(locale: AppLanguage.preferredLocale())
    }

    func label(locale: Locale) -> String {
        switch self {
        case .green:  return L10n.string("Green", locale: locale)
        case .blue:   return L10n.string("Blue", locale: locale)
        case .orange: return L10n.string("Orange", locale: locale)
        case .purple: return L10n.string("Purple", locale: locale)
        case .white:  return L10n.string("White", locale: locale)
        }
    }

    var color: Color {
        switch self {
        case .green:  return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .blue:   return Color(red: 0.25, green: 0.55, blue: 1.00)
        case .orange: return Color(red: 0.86, green: 0.82, blue: 0.12)
        case .purple: return Color(red: 0.72, green: 0.35, blue: 1.00)
        case .white:  return Color(white: 0.90)
        }
    }
}
