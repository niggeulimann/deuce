import Foundation
import SwiftData

enum DeuceSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [MatchRecord.self] }

    @Model
    final class MatchRecord {
        var date: Date
        var surface: String
        var noAd: Bool
        var gamesPerSet: Int
        var setsToWin: Int
        var isComplete: Bool

        var setsTop: Int
        var setsBottom: Int
        var setScoresTop: [Int]
        var setScoresBottom: [Int]
        var currentGamesTop: Int
        var currentGamesBottom: Int
        var currentPointsTop: Int
        var currentPointsBottom: Int
        var didWin: Bool

        init(date: Date = .now,
             surface: String,
             noAd: Bool,
             gamesPerSet: Int,
             setsToWin: Int,
             isComplete: Bool,
             setsTop: Int,
             setsBottom: Int,
             setScoresTop: [Int],
             setScoresBottom: [Int],
             currentGamesTop: Int,
             currentGamesBottom: Int,
             currentPointsTop: Int,
             currentPointsBottom: Int,
             didWin: Bool) {
            self.date                = date
            self.surface             = surface
            self.noAd                = noAd
            self.gamesPerSet         = gamesPerSet
            self.setsToWin           = setsToWin
            self.isComplete          = isComplete
            self.setsTop             = setsTop
            self.setsBottom          = setsBottom
            self.setScoresTop        = setScoresTop
            self.setScoresBottom     = setScoresBottom
            self.currentGamesTop     = currentGamesTop
            self.currentGamesBottom  = currentGamesBottom
            self.currentPointsTop    = currentPointsTop
            self.currentPointsBottom = currentPointsBottom
            self.didWin              = didWin
        }
    }
}

enum DeuceSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] { [MatchRecord.self, KnownOpponent.self] }

    @Model
    final class MatchRecord {
        var date: Date
        var surface: String
        var noAd: Bool
        var gamesPerSet: Int
        var setsToWin: Int
        var isComplete: Bool

        var setsTop: Int
        var setsBottom: Int
        var setScoresTop: [Int]
        var setScoresBottom: [Int]
        var currentGamesTop: Int
        var currentGamesBottom: Int
        var currentPointsTop: Int
        var currentPointsBottom: Int
        var didWin: Bool

        // Opponent name (editable from history)
        var opponentName: String = ""

        // Timestamps, in seconds since matchStartDate.
        var matchStartDate: Date = Date()
        var firstPointOffset: Double = -1
        var pointOffsets: [Double] = []
        var gameOffsets: [Double] = []
        var setOffsets: [Double] = []

        init(date: Date = .now,
             surface: String,
             noAd: Bool,
             gamesPerSet: Int,
             setsToWin: Int,
             isComplete: Bool,
             setsTop: Int,
             setsBottom: Int,
             setScoresTop: [Int],
             setScoresBottom: [Int],
             currentGamesTop: Int,
             currentGamesBottom: Int,
             currentPointsTop: Int,
             currentPointsBottom: Int,
             didWin: Bool,
             opponentName: String = "",
             matchStartDate: Date = Date(),
             firstPointOffset: Double = -1,
             pointOffsets: [Double] = [],
             gameOffsets: [Double] = [],
             setOffsets: [Double] = []) {
            self.date                = date
            self.surface             = surface
            self.noAd                = noAd
            self.gamesPerSet         = gamesPerSet
            self.setsToWin           = setsToWin
            self.isComplete          = isComplete
            self.setsTop             = setsTop
            self.setsBottom          = setsBottom
            self.setScoresTop        = setScoresTop
            self.setScoresBottom     = setScoresBottom
            self.currentGamesTop     = currentGamesTop
            self.currentGamesBottom  = currentGamesBottom
            self.currentPointsTop    = currentPointsTop
            self.currentPointsBottom = currentPointsBottom
            self.didWin              = didWin
            self.opponentName        = opponentName
            self.matchStartDate      = matchStartDate
            self.firstPointOffset    = firstPointOffset
            self.pointOffsets        = pointOffsets
            self.gameOffsets         = gameOffsets
            self.setOffsets          = setOffsets
        }
    }

    @Model
    final class KnownOpponent {
        var name: String
        var lastPlayed: Date

        init(name: String, lastPlayed: Date = .now) {
            self.name       = name
            self.lastPlayed = lastPlayed
        }
    }
}

enum DeuceSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 2, 0)
    static var models: [any PersistentModel.Type] { [MatchRecord.self, KnownOpponent.self] }

    @Model
    final class MatchRecord {
        // Stable, store-independent identity for Watch→iPhone sync dedupe.
        var id: UUID = UUID()

        var date: Date
        var surface: String
        var noAd: Bool
        var gamesPerSet: Int
        var setsToWin: Int
        var isComplete: Bool

        var setsTop: Int
        var setsBottom: Int
        var setScoresTop: [Int]
        var setScoresBottom: [Int]
        var currentGamesTop: Int
        var currentGamesBottom: Int
        var currentPointsTop: Int
        var currentPointsBottom: Int
        var didWin: Bool

        var opponentName: String = ""
        // Free-text notes, edited on the iPhone companion.
        var notes: String = ""

        var matchStartDate: Date = Date()
        var firstPointOffset: Double = -1
        var pointOffsets: [Double] = []
        var gameOffsets: [Double] = []
        var setOffsets: [Double] = []

        init(id: UUID = UUID(),
             date: Date = .now,
             surface: String,
             noAd: Bool,
             gamesPerSet: Int,
             setsToWin: Int,
             isComplete: Bool,
             setsTop: Int,
             setsBottom: Int,
             setScoresTop: [Int],
             setScoresBottom: [Int],
             currentGamesTop: Int,
             currentGamesBottom: Int,
             currentPointsTop: Int,
             currentPointsBottom: Int,
             didWin: Bool,
             opponentName: String = "",
             notes: String = "",
             matchStartDate: Date = Date(),
             firstPointOffset: Double = -1,
             pointOffsets: [Double] = [],
             gameOffsets: [Double] = [],
             setOffsets: [Double] = []) {
            self.id                  = id
            self.date                = date
            self.surface             = surface
            self.noAd                = noAd
            self.gamesPerSet         = gamesPerSet
            self.setsToWin           = setsToWin
            self.isComplete          = isComplete
            self.setsTop             = setsTop
            self.setsBottom          = setsBottom
            self.setScoresTop        = setScoresTop
            self.setScoresBottom     = setScoresBottom
            self.currentGamesTop     = currentGamesTop
            self.currentGamesBottom  = currentGamesBottom
            self.currentPointsTop    = currentPointsTop
            self.currentPointsBottom = currentPointsBottom
            self.didWin              = didWin
            self.opponentName        = opponentName
            self.notes               = notes
            self.matchStartDate      = matchStartDate
            self.firstPointOffset    = firstPointOffset
            self.pointOffsets        = pointOffsets
            self.gameOffsets         = gameOffsets
            self.setOffsets          = setOffsets
        }
    }

    @Model
    final class KnownOpponent {
        var name: String
        var lastPlayed: Date

        init(name: String, lastPlayed: Date = .now) {
            self.name       = name
            self.lastPlayed = lastPlayed
        }
    }
}

enum DeuceSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 3, 0)
    static var models: [any PersistentModel.Type] { [MatchRecord.self, KnownOpponent.self] }

    @Model
    final class MatchRecord {
        var id: UUID = UUID()
        var syncUpdatedAt: Date = Date()
        var isDeleted: Bool = false

        var date: Date
        var surface: String
        var noAd: Bool
        var gamesPerSet: Int
        var setsToWin: Int
        var isComplete: Bool

        var setsTop: Int
        var setsBottom: Int
        var setScoresTop: [Int]
        var setScoresBottom: [Int]
        var currentGamesTop: Int
        var currentGamesBottom: Int
        var currentPointsTop: Int
        var currentPointsBottom: Int
        var didWin: Bool

        var opponentName: String = ""
        var notes: String = ""

        var matchStartDate: Date = Date()
        var firstPointOffset: Double = -1
        var pointOffsets: [Double] = []
        var gameOffsets: [Double] = []
        var setOffsets: [Double] = []

        init(id: UUID = UUID(),
             syncUpdatedAt: Date = Date(),
             isDeleted: Bool = false,
             date: Date = .now,
             surface: String,
             noAd: Bool,
             gamesPerSet: Int,
             setsToWin: Int,
             isComplete: Bool,
             setsTop: Int,
             setsBottom: Int,
             setScoresTop: [Int],
             setScoresBottom: [Int],
             currentGamesTop: Int,
             currentGamesBottom: Int,
             currentPointsTop: Int,
             currentPointsBottom: Int,
             didWin: Bool,
             opponentName: String = "",
             notes: String = "",
             matchStartDate: Date = Date(),
             firstPointOffset: Double = -1,
             pointOffsets: [Double] = [],
             gameOffsets: [Double] = [],
             setOffsets: [Double] = []) {
            self.id                  = id
            self.syncUpdatedAt       = syncUpdatedAt
            self.isDeleted           = isDeleted
            self.date                = date
            self.surface             = surface
            self.noAd                = noAd
            self.gamesPerSet         = gamesPerSet
            self.setsToWin           = setsToWin
            self.isComplete          = isComplete
            self.setsTop             = setsTop
            self.setsBottom          = setsBottom
            self.setScoresTop        = setScoresTop
            self.setScoresBottom     = setScoresBottom
            self.currentGamesTop     = currentGamesTop
            self.currentGamesBottom  = currentGamesBottom
            self.currentPointsTop    = currentPointsTop
            self.currentPointsBottom = currentPointsBottom
            self.didWin              = didWin
            self.opponentName        = opponentName
            self.notes               = notes
            self.matchStartDate      = matchStartDate
            self.firstPointOffset    = firstPointOffset
            self.pointOffsets        = pointOffsets
            self.gameOffsets         = gameOffsets
            self.setOffsets          = setOffsets
        }
    }

    @Model
    final class KnownOpponent {
        var name: String
        var lastPlayed: Date

        init(name: String, lastPlayed: Date = .now) {
            self.name       = name
            self.lastPlayed = lastPlayed
        }
    }
}

typealias MatchRecord = DeuceSchemaV4.MatchRecord
typealias KnownOpponent = DeuceSchemaV4.KnownOpponent

enum DeuceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DeuceSchemaV1.self, DeuceSchemaV2.self, DeuceSchemaV3.self, DeuceSchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: DeuceSchemaV1.self,
        toVersion: DeuceSchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: DeuceSchemaV2.self,
        toVersion: DeuceSchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: DeuceSchemaV3.self,
        toVersion: DeuceSchemaV4.self
    )
}

extension MatchRecord {
    var isVisible: Bool { !isDeleted }

    func markModified() {
        syncUpdatedAt = Date()
    }

    func markDeleted() {
        isDeleted = true
        markModified()
    }

    func hasSameSyncContent(as dto: MatchRecordDTO) -> Bool {
        isDeleted == dto.isDeleted &&
        date == dto.date &&
        surface == dto.surface &&
        noAd == dto.noAd &&
        gamesPerSet == dto.gamesPerSet &&
        setsToWin == dto.setsToWin &&
        isComplete == dto.isComplete &&
        setsTop == dto.setsTop &&
        setsBottom == dto.setsBottom &&
        setScoresTop == dto.setScoresTop &&
        setScoresBottom == dto.setScoresBottom &&
        currentGamesTop == dto.currentGamesTop &&
        currentGamesBottom == dto.currentGamesBottom &&
        currentPointsTop == dto.currentPointsTop &&
        currentPointsBottom == dto.currentPointsBottom &&
        didWin == dto.didWin &&
        opponentName == dto.opponentName &&
        notes == dto.notes &&
        matchStartDate == dto.matchStartDate &&
        firstPointOffset == dto.firstPointOffset &&
        pointOffsets == dto.pointOffsets &&
        gameOffsets == dto.gameOffsets &&
        setOffsets == dto.setOffsets
    }

    func apply(_ dto: MatchRecordDTO) {
        syncUpdatedAt       = dto.syncUpdatedAt
        isDeleted           = dto.isDeleted
        date                = dto.date
        surface             = dto.surface
        noAd                = dto.noAd
        gamesPerSet         = dto.gamesPerSet
        setsToWin           = dto.setsToWin
        isComplete          = dto.isComplete
        setsTop             = dto.setsTop
        setsBottom          = dto.setsBottom
        setScoresTop        = dto.setScoresTop
        setScoresBottom     = dto.setScoresBottom
        currentGamesTop     = dto.currentGamesTop
        currentGamesBottom  = dto.currentGamesBottom
        currentPointsTop    = dto.currentPointsTop
        currentPointsBottom = dto.currentPointsBottom
        didWin              = dto.didWin
        opponentName        = dto.opponentName
        notes               = dto.notes
        matchStartDate      = dto.matchStartDate
        firstPointOffset    = dto.firstPointOffset
        pointOffsets        = dto.pointOffsets
        gameOffsets         = dto.gameOffsets
        setOffsets          = dto.setOffsets
    }
}

#if os(watchOS)
extension MatchViewModel {
    func makeRecord(isComplete: Bool) -> MatchRecord {
        MatchRecord(
            surface:             surface.rawValue,
            noAd:                state.noAd,
            gamesPerSet:         state.gamesPerSet,
            setsToWin:           state.setsToWin,
            isComplete:          isComplete,
            setsTop:             state.setsWon[.top]!,
            setsBottom:          state.setsWon[.bottom]!,
            setScoresTop:        state.setHistory.map(\.top),
            setScoresBottom:     state.setHistory.map(\.bottom),
            currentGamesTop:     state.gamesWon[.top]!,
            currentGamesBottom:  state.gamesWon[.bottom]!,
            currentPointsTop:    state.points[.top]!,
            currentPointsBottom: state.points[.bottom]!,
            didWin:              state.setsWon[.bottom]! >= state.setsToWin,
            matchStartDate:      matchStartDate,
            firstPointOffset:    firstPointOffset,
            pointOffsets:        pointOffsets,
            gameOffsets:         gameOffsets,
            setOffsets:          setOffsets
        )
    }
}
#endif
