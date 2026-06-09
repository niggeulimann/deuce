import SwiftUI

enum CourtSurface: String, CaseIterable, Identifiable {
    case clay, grass, hard, carpet

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clay:   return String(localized: "Clay")
        case .grass:  return String(localized: "Grass")
        case .hard:   return String(localized: "Hard")
        case .carpet: return String(localized: "Indoor")
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
