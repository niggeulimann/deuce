import Foundation
import SwiftData

@Model
final class KnownOpponent {
    var name: String
    var lastPlayed: Date

    init(name: String, lastPlayed: Date = .now) {
        self.name       = name
        self.lastPlayed = lastPlayed
    }
}
