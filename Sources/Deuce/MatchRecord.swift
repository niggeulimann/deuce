import Foundation
import SwiftData

@Model
final class MatchRecord {
    var date: Date
    var surface: String        // CourtSurface.rawValue
    var noAd: Bool
    var gamesPerSet: Int
    var setsToWin: Int
    var isComplete: Bool       // false = abgebrochen

    // Sets won totals
    var setsTop: Int
    var setsBottom: Int

    // Per-set game scores, parallel arrays (index = set number)
    var setScoresTop: [Int]
    var setScoresBottom: [Int]

    // Current (unfinished) set at time of save
    var currentGamesTop: Int
    var currentGamesBottom: Int

    // Current game point score at time of save
    var currentPointsTop: Int
    var currentPointsBottom: Int

    var didWin: Bool           // Du (bottom) hat gewonnen

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
        self.date               = date
        self.surface            = surface
        self.noAd               = noAd
        self.gamesPerSet        = gamesPerSet
        self.setsToWin          = setsToWin
        self.isComplete         = isComplete
        self.setsTop            = setsTop
        self.setsBottom         = setsBottom
        self.setScoresTop       = setScoresTop
        self.setScoresBottom    = setScoresBottom
        self.currentGamesTop    = currentGamesTop
        self.currentGamesBottom = currentGamesBottom
        self.currentPointsTop   = currentPointsTop
        self.currentPointsBottom = currentPointsBottom
        self.didWin             = didWin
    }
}

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
            didWin:              state.setsWon[.bottom]! >= state.setsToWin
        )
    }
}
