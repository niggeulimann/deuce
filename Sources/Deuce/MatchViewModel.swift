import Foundation
import Observation

@Observable
final class MatchViewModel {

    private(set) var state: GameState
    private var history: [GameState] = []

    var surface: CourtSurface = .clay

    init(server: Side = .bottom, noAd: Bool = false, surface: CourtSurface = .clay) {
        state = GameState(server: server, noAd: noAd)
        self.surface = surface
    }

    // MARK: - Derived display values

    var topScore: String    { ScoringEngine.scoreLabel(for: .top, in: state) }
    var bottomScore: String { ScoringEngine.scoreLabel(for: .bottom, in: state) }
    var topGames: Int       { state.gamesWon[.top]! }
    var bottomGames: Int    { state.gamesWon[.bottom]! }
    var server: Side        { state.server }
    var serveBox: ServeBox  { ScoringEngine.serveBox(in: state) }
    var canUndo: Bool       { !history.isEmpty }

    // MARK: - Mutating actions

    func point(for side: Side) -> Bool {
        history.append(state)
        let result = ScoringEngine.applyPoint(to: side, state: state)
        state = result.newState
        return result.gameWon
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        state = previous
    }

    func resetMatch() {
        history.removeAll()
        state = GameState(server: state.server, noAd: state.noAd)
    }

    // MARK: - Settings

    var noAd: Bool {
        get { state.noAd }
        set { history.removeAll(); state = GameState(server: state.server, noAd: newValue) }
    }
}
