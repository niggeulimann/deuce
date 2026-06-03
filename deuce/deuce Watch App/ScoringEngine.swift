import Foundation

// MARK: - Domain Types

enum Side: CaseIterable {
    case top, bottom
    var opposite: Side { self == .top ? .bottom : .top }
}

enum ServeBox {
    case left, right
}

struct GameState: Equatable {
    var points: [Side: Int]    = [.top: 0, .bottom: 0]
    var gamesWon: [Side: Int]  = [.top: 0, .bottom: 0]
    var setsWon: [Side: Int]   = [.top: 0, .bottom: 0]
    // Games score of each finished set, in order: [(top, bottom), …]
    var setHistory: [(top: Int, bottom: Int)] = []
    var server: Side   = .bottom
    var noAd: Bool     = false
    var gamesPerSet: Int = 6   // first to this many games (with 2-game lead)
    var setsToWin: Int   = 2   // first to this many sets wins the match

    // Equatable manually because tuples aren't auto-Equatable
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        lhs.points      == rhs.points      &&
        lhs.gamesWon    == rhs.gamesWon    &&
        lhs.setsWon     == rhs.setsWon     &&
        lhs.setHistory.map(\.top)    == rhs.setHistory.map(\.top)    &&
        lhs.setHistory.map(\.bottom) == rhs.setHistory.map(\.bottom) &&
        lhs.server      == rhs.server      &&
        lhs.noAd        == rhs.noAd        &&
        lhs.gamesPerSet == rhs.gamesPerSet &&
        lhs.setsToWin   == rhs.setsToWin
    }
}

// MARK: - Engine

struct ScoringEngine {

    static func isTiebreak(_ state: GameState) -> Bool {
        let target = state.gamesPerSet
        return state.gamesWon[.top] == target && state.gamesWon[.bottom] == target
    }

    static func displayServer(in state: GameState) -> Side {
        guard isTiebreak(state) else { return state.server }
        let pointsPlayed = state.points[.top]! + state.points[.bottom]!
        guard pointsPlayed > 0 else { return state.server }
        return ((pointsPlayed + 1) / 2) % 2 == 0 ? state.server : state.server.opposite
    }

    static func scoreLabel(for side: Side, in state: GameState) -> String {
        if isTiebreak(state) {
            return "\(state.points[side]!)"
        }

        let mine   = state.points[side]!
        let theirs = state.points[side.opposite]!
        let deuce  = mine >= 3 && theirs >= 3
        if deuce {
            if mine == theirs { return "Deuce" }
            return mine > theirs ? "Ad" : "40"
        }
        switch mine {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        default: return "40"
        }
    }

    static func serveBox(in state: GameState) -> ServeBox {
        let total = state.points[.top]! + state.points[.bottom]!
        switch displayServer(in: state) {
        case .bottom: return total % 2 == 0 ? .right : .left
        case .top:    return total % 2 == 0 ? .left  : .right
        }
    }

    static func isGameWon(by side: Side, in state: GameState) -> Bool {
        let mine   = state.points[side]!
        let theirs = state.points[side.opposite]!
        if isTiebreak(state) { return mine >= 7 && (mine - theirs) >= 2 }
        if state.noAd { return mine >= 4 && mine > theirs }
        return mine >= 4 && (mine - theirs) >= 2
    }

    static func isSetWon(by side: Side, in state: GameState) -> Bool {
        let mine   = state.gamesWon[side]!
        let theirs = state.gamesWon[side.opposite]!
        let target = state.gamesPerSet
        if mine >= target && (mine - theirs) >= 2 { return true }
        // Tiebreak: target+1 vs target (e.g. 7-6)
        if mine == target + 1 && theirs == target  { return true }
        return false
    }

    // Returns (newState, gameWon, setWon)
    static func applyPoint(
        to side: Side,
        state: GameState
    ) -> (newState: GameState, gameWon: Bool, setWon: Bool) {
        var next = state
        next.points[side]! += 1

        guard isGameWon(by: side, in: next) else {
            return (next, false, false)
        }

        // Game won
        next.gamesWon[side]! += 1
        next.points = [.top: 0, .bottom: 0]
        next.server = state.server.opposite

        guard isSetWon(by: side, in: next) else {
            return (next, true, false)
        }

        // Set won
        next.setsWon[side]! += 1
        let snap = (top: next.gamesWon[.top]!, bottom: next.gamesWon[.bottom]!)
        next.setHistory.append(snap)
        next.gamesWon = [.top: 0, .bottom: 0]
        return (next, true, true)
    }
}
