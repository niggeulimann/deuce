import Foundation
import SwiftData

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

    // Timestamps — seconds since matchStartDate
    // firstPointOffset: warmup duration
    // pointOffsets: time of each point; gap between consecutive = rally duration
    // gameOffsets / setOffsets: for pacing analysis
    var matchStartDate: Date = Date()
    var firstPointOffset: Double = -1   // -1 = not yet set
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
