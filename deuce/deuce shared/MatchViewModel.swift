import Foundation
import Observation
#if os(watchOS)
import HealthKit
#endif

@Observable
final class MatchViewModel: Identifiable {
    let id = UUID()

    private(set) var state: GameState
    private var history: [GameState] = []
    private(set) var sideSwitch = false

    var surface: CourtSurface = .clay

    // MARK: - Timestamp tracking
    let matchStartDate: Date
    // End of warmup in seconds since matchStartDate; legacy matches may set it on first point.
    private(set) var firstPointOffset: Double = -1
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
         surface: CourtSurface = .clay,
         matchStartDate: Date = Date()) {
        state = GameState(server: server, noAd: noAd,
                         gamesPerSet: gamesPerSet, setsToWin: setsToWin)
        self.surface = surface
        self.matchStartDate = matchStartDate
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

    /// Open-ended match (no set target): plays on until ended manually.
    var isOpenEnded: Bool { state.setsToWin == 0 }

    var matchWon: Side? {
        // Open matches never auto-end; the user ends them via "End Match".
        guard state.setsToWin > 0 else { return nil }
        if state.setsWon[.top]!    >= state.setsToWin { return .top }
        if state.setsWon[.bottom]! >= state.setsToWin { return .bottom }
        return nil
    }

    /// Who is currently ahead (sets → games → points). Used to decide the result
    /// of an open match when it is ended manually. `nil` when exactly level.
    var currentLeader: Side? {
        if state.setsWon[.top]!  != state.setsWon[.bottom]! {
            return state.setsWon[.top]!  > state.setsWon[.bottom]!  ? .top : .bottom
        }
        if state.gamesWon[.top]! != state.gamesWon[.bottom]! {
            return state.gamesWon[.top]! > state.gamesWon[.bottom]! ? .top : .bottom
        }
        if state.points[.top]!   != state.points[.bottom]! {
            return state.points[.top]!   > state.points[.bottom]!   ? .top : .bottom
        }
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

    func startMatch(
        server: Side,
        noAd: Bool,
        gamesPerSet: Int,
        setsToWin: Int,
        surface: CourtSurface,
        at date: Date = Date()
    ) {
        guard history.isEmpty, pointOffsets.isEmpty else { return }

        state = GameState(
            server: server,
            noAd: noAd,
            gamesPerSet: gamesPerSet,
            setsToWin: setsToWin
        )
        self.surface = surface
        firstPointOffset = max(0, date.timeIntervalSince(matchStartDate))
    }

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

#if os(watchOS)

/// Minimal HealthKit workout session used **only on the watch**. An active
/// `HKWorkoutSession` keeps the app frontmost (Always-On keeps showing the app
/// and raising the wrist returns to it instead of the clock face) for the whole
/// warmup + match, and saves the session to Health as a Tennis workout (useful
/// for the HealthFit → Strava export). Lives here so it ships with every target
/// that already compiles MatchViewModel.swift without extra build-phase wiring.
@MainActor
final class HealthManager: NSObject {
    static let shared = HealthManager()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var isStarting = false

    private override init() { super.init() }

    private var isActive: Bool { session != nil || isStarting }

    /// Start a tennis workout if none is running. Requests authorization on first use.
    /// Safe to call repeatedly (e.g. when entering warmup).
    func startWorkout() {
        guard HKHealthStore.isHealthDataAvailable(), !isActive else { return }
        isStarting = true
        Task { await begin() }
    }

    /// End the running workout. The session delegate finalizes and saves it.
    func stopWorkout() {
        isStarting = false
        session?.end()
    }

    private func begin() async {
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        // Proceed even if this throws/denies – a workout still saves duration + type.
        try? await store.requestAuthorization(toShare: share, read: read)
        guard isStarting else { return }   // stopped while awaiting authorization

        let config = HKWorkoutConfiguration()
        config.activityType = .tennis
        config.locationType  = .outdoor
        do {
            let newSession = try HKWorkoutSession(healthStore: store, configuration: config)
            let newBuilder = newSession.associatedWorkoutBuilder()
            newBuilder.dataSource = HKLiveWorkoutDataSource(
                healthStore: store, workoutConfiguration: config
            )
            newSession.delegate = self
            session = newSession
            builder = newBuilder
            let start = Date()
            newSession.startActivity(with: start)
            try await newBuilder.beginCollection(at: start)
        } catch {
            session = nil
            builder = nil
        }
        isStarting = false
    }

    private func finish(at date: Date) async {
        guard let builder else { return }
        try? await builder.endCollection(at: date)
        _ = try? await builder.finishWorkout()
        self.builder = nil
        self.session = nil
    }
}

extension HealthManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ session: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended else { return }
        Task { @MainActor in await self.finish(at: date) }
    }

    nonisolated func workoutSession(
        _ session: HKWorkoutSession, didFailWithError error: Error
    ) {}
}
#endif
