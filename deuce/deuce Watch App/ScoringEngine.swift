import Foundation

// MARK: - Domain Types

enum Side: CaseIterable {
    case top, bottom
    var opposite: Side { self == .top ? .bottom : .top }
}

// Which half of the court the server stands in (screen-relative: left = left on screen)
enum ServeBox {
    case left, right
}

enum PointDisplay {
    case love, fifteen, thirty, forty, advantage, game
}

struct GameState: Equatable {
    var points: [Side: Int] = [.top: 0, .bottom: 0]
    var gamesWon: [Side: Int] = [.top: 0, .bottom: 0]
    var server: Side = .bottom
    var noAd: Bool = false
}

// MARK: - Engine

struct ScoringEngine {

    static func scoreLabel(for side: Side, in state: GameState) -> String {
        let mine = state.points[side]!
        let theirs = state.points[side.opposite]!
        let deuce = mine >= 3 && theirs >= 3

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

    // Serve box alternates every point. Deuce side (even points) = server's right.
    // From screen perspective: bottom server's right = screen-right; top server's right = screen-left.
    static func serveBox(in state: GameState) -> ServeBox {
        let totalPoints = state.points[.top]! + state.points[.bottom]!
        let isDeucePoint = totalPoints % 2 == 0   // 0, 2, 4 … = deuce side
        switch state.server {
        case .bottom: return isDeucePoint ? .right : .left
        case .top:    return isDeucePoint ? .left  : .right
        }
    }

    static func isGameWon(by side: Side, in state: GameState) -> Bool {
        let mine = state.points[side]!
        let theirs = state.points[side.opposite]!
        if state.noAd { return mine >= 4 && mine > theirs }
        return mine >= 4 && (mine - theirs) >= 2
    }

    static func applyPoint(to side: Side, state: GameState) -> (newState: GameState, gameWon: Bool) {
        var next = state
        next.points[side]! += 1

        if isGameWon(by: side, in: next) {
            next.gamesWon[side]! += 1
            next.points = [.top: 0, .bottom: 0]
            next.server = state.server.opposite   // serve alternates after each game
            return (next, true)
        }
        return (next, false)
    }
}
