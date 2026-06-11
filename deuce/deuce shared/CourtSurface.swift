import SwiftUI

enum CourtSurface: String, CaseIterable, Identifiable {
    case clay, grass, hard, carpet

    var id: String { rawValue }

    var label: String {
        label(locale: AppLanguage.preferredLocale())
    }

    func label(locale: Locale) -> String {
        switch self {
        case .clay:   return L10n.string("Clay", locale: locale)
        case .grass:  return L10n.string("Grass", locale: locale)
        case .hard:   return L10n.string("Hard", locale: locale)
        case .carpet: return L10n.string("Indoor", locale: locale)
        }
    }

    var colorTop: Color {
        switch self {
        case .clay:   return Color(red: 0.72, green: 0.38, blue: 0.22)
        case .grass:  return Color(red: 0.13, green: 0.42, blue: 0.18)
        case .hard:   return Color(red: 0.15, green: 0.35, blue: 0.62)
        case .carpet: return Color(red: 0.28, green: 0.22, blue: 0.45)
        }
    }

    var colorBottom: Color {
        switch self {
        case .clay:   return Color(red: 0.63, green: 0.32, blue: 0.17)
        case .grass:  return Color(red: 0.10, green: 0.35, blue: 0.14)
        case .hard:   return Color(red: 0.12, green: 0.29, blue: 0.54)
        case .carpet: return Color(red: 0.23, green: 0.18, blue: 0.38)
        }
    }

    var accentColor: Color { colorTop }
}
