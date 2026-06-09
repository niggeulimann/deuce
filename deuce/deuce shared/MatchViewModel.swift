import Foundation
import Observation

@Observable
final class MatchViewModel {

    private(set) var state: GameState
    private var history: [GameState] = []
    private(set) var sideSwitch = false

    var surface: CourtSurface = .clay

    // MARK: - Timestamp tracking
    let matchStartDate = Date()
    private(set) var firstPointOffset: Double = -1   // seconds since matchStartDate; -1 = not yet
    private(set) var pointOffsets: [Double] = []
    private(set) var gameOffsets:  [Double] = []
    private(set) var setOffsets:   [Double] = []
    // Undo stack mirrors state history so we can pop timestamps on undo
    private var pointOffsetHistory: [[Double]] = []
    private var gameOffsetHistory:  [[Double]] = []
    private var setOffsetHistory:   [[Double]] = []
    private var firstPointHistory:  [Double]   = []

    init(server: Side = .bottom, noAd: Bool = false,
         gamesPerSet: Int = 6, setsToWin: Int = 2,
         surface: CourtSurface = .clay) {
        state = GameState(server: server, noAd: noAd,
                         gamesPerSet: gamesPerSet, setsToWin: setsToWin)
        self.surface = surface
    }

    // MARK: - Derived display

    var topScore: String    { ScoringEngine.scoreLabel(for: .top, in: state) }
    var bottomScore: String { ScoringEngine.scoreLabel(for: .bottom, in: state) }
    var topGames: Int       { state.gamesWon[.top]! }
    var bottomGames: Int    { state.gamesWon[.bottom]! }
    var topSets: Int        { state.setsWon[.top]! }
    var bottomSets: Int     { state.setsWon[.bottom]! }
    var setHistory: [(top: Int, bottom: Int)] { state.setHistory }
    var server: Side        { ScoringEngine.displayServer(in: state) }
    var serveBox: ServeBox  { ScoringEngine.serveBox(in: state) }
    var canUndo: Bool       { !history.isEmpty }

    var matchWon: Side? {
        if state.setsWon[.top]!    >= state.setsToWin { return .top }
        if state.setsWon[.bottom]! >= state.setsToWin { return .bottom }
        return nil
    }

    // MARK: - Actions

    @discardableResult
    func point(for side: Side) -> (gameWon: Bool, setWon: Bool) {
        // Snapshot before applying
        history.append(state)
        pointOffsetHistory.append(pointOffsets)
        gameOffsetHistory.append(gameOffsets)
        setOffsetHistory.append(setOffsets)
        firstPointHistory.append(firstPointOffset)

        let now = Date().timeIntervalSince(matchStartDate)

        // Record first-point (warmup end)
        if firstPointOffset < 0 { firstPointOffset = now }

        let result = ScoringEngine.applyPoint(to: side, state: state)
        state = result.newState

        pointOffsets.append(now)
        if result.gameWon { gameOffsets.append(now) }
        if result.setWon  {
            setOffsets.append(now)
            sideSwitch = true
        }

        return (result.gameWon, result.setWon)
    }

    func dismissSideSwitch() { sideSwitch = false }

    func undo() {
        guard let previous = history.popLast() else { return }
        state             = previous
        pointOffsets      = pointOffsetHistory.popLast() ?? []
        gameOffsets       = gameOffsetHistory.popLast()  ?? []
        setOffsets        = setOffsetHistory.popLast()   ?? []
        firstPointOffset  = firstPointHistory.popLast()  ?? -1
        sideSwitch        = false
    }

    func resetMatch() {
        history.removeAll()
        pointOffsetHistory.removeAll(); gameOffsetHistory.removeAll()
        setOffsetHistory.removeAll();   firstPointHistory.removeAll()
        pointOffsets = []; gameOffsets = []; setOffsets = []
        firstPointOffset = -1
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
