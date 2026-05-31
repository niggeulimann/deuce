import Foundation
import Observation

@Observable
final class MatchViewModel {

    private(set) var state: GameState
    private var history: [GameState] = []

    // Set to true for one tick after a set is won → triggers side-switch overlay
    private(set) var sideSwitch = false

    var surface: CourtSurface = .clay

    init(server: Side = .bottom, noAd: Bool = false,
         gamesPerSet: Int = 6, setsToWin: Int = 2,
         surface: CourtSurface = .clay) {
        state = GameState(server: server, noAd: noAd,
                         gamesPerSet: gamesPerSet, setsToWin: setsToWin)
        self.surface = surface
    }

    // MARK: - Derived display

    var topScore: String   { ScoringEngine.scoreLabel(for: .top, in: state) }
    var bottomScore: String{ ScoringEngine.scoreLabel(for: .bottom, in: state) }
    var topGames: Int      { state.gamesWon[.top]! }
    var bottomGames: Int   { state.gamesWon[.bottom]! }
    var topSets: Int       { state.setsWon[.top]! }
    var bottomSets: Int    { state.setsWon[.bottom]! }
    var setHistory: [(top: Int, bottom: Int)] { state.setHistory }
    var server: Side       { state.server }
    var serveBox: ServeBox { ScoringEngine.serveBox(in: state) }
    var canUndo: Bool      { !history.isEmpty }

    var matchWon: Side? {
        if state.setsWon[.top]!    >= state.setsToWin { return .top }
        if state.setsWon[.bottom]! >= state.setsToWin { return .bottom }
        return nil
    }

    // MARK: - Actions

    @discardableResult
    func point(for side: Side) -> (gameWon: Bool, setWon: Bool) {
        history.append(state)
        let result = ScoringEngine.applyPoint(to: side, state: state)
        state = result.newState
        if result.setWon {
            sideSwitch = true
        }
        return (result.gameWon, result.setWon)
    }

    func dismissSideSwitch() { sideSwitch = false }

    func undo() {
        guard let previous = history.popLast() else { return }
        state = previous
        sideSwitch = false
    }

    func resetMatch() {
        history.removeAll()
        sideSwitch = false
        state = GameState(server: state.server, noAd: state.noAd,
                         gamesPerSet: state.gamesPerSet, setsToWin: state.setsToWin)
    }

    // MARK: - Settings pass-through

    var noAd: Bool {
        get { state.noAd }
        set { reset(noAd: newValue) }
    }

    private func reset(noAd: Bool? = nil) {
        history.removeAll()
        sideSwitch = false
        state = GameState(server: state.server,
                         noAd: noAd ?? state.noAd,
                         gamesPerSet: state.gamesPerSet,
                         setsToWin: state.setsToWin)
    }
}
