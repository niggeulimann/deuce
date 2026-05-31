import Testing
@testable import Deuce

// MARK: - Basic point progression

@Test func loveToGame() {
    var state = GameState()
    var gameWon = false

    for _ in 0..<4 {
        let result = ScoringEngine.applyPoint(to: .top, state: state)
        state = result.newState
        gameWon = result.gameWon
    }

    #expect(gameWon)
    #expect(state.gamesWon[.top] == 1)
    #expect(state.points[.top] == 0)
    #expect(state.points[.bottom] == 0)
}

@Test func scoreLabelsProgression() {
    var state = GameState()
    let expected = ["0", "15", "30", "40"]

    for (i, label) in expected.enumerated() {
        #expect(ScoringEngine.scoreLabel(for: .top, in: state) == label, "step \(i)")
        let result = ScoringEngine.applyPoint(to: .top, state: state)
        state = result.newState
    }
}

// MARK: - Deuce / Advantage

@Test func reachDeuce() {
    var state = GameState()
    // both reach 40
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .top, state: state).newState }
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .bottom, state: state).newState }

    #expect(ScoringEngine.scoreLabel(for: .top, in: state) == "Deuce")
    #expect(ScoringEngine.scoreLabel(for: .bottom, in: state) == "Deuce")
}

@Test func advantageAndBackToDeuce() {
    var state = GameState()
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .top, state: state).newState }
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .bottom, state: state).newState }

    // top takes advantage
    state = ScoringEngine.applyPoint(to: .top, state: state).newState
    #expect(ScoringEngine.scoreLabel(for: .top, in: state) == "Ad")
    #expect(ScoringEngine.scoreLabel(for: .bottom, in: state) == "40")

    // bottom equalises → deuce again
    state = ScoringEngine.applyPoint(to: .bottom, state: state).newState
    #expect(ScoringEngine.scoreLabel(for: .top, in: state) == "Deuce")
}

@Test func winFromAdvantage() {
    var state = GameState()
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .top, state: state).newState }
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .bottom, state: state).newState }

    state = ScoringEngine.applyPoint(to: .top, state: state).newState // Ad
    let result = ScoringEngine.applyPoint(to: .top, state: state)

    #expect(result.gameWon)
    #expect(result.newState.gamesWon[.top] == 1)
}

@Test func cannotWinFromDeuceWithOnePoint() {
    var state = GameState()
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .top, state: state).newState }
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .bottom, state: state).newState }

    let result = ScoringEngine.applyPoint(to: .top, state: state)
    #expect(!result.gameWon)
}

// MARK: - No-Ad

@Test func noAdWinOnFifthPoint() {
    var state = GameState(noAd: true)
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .top, state: state).newState }
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .bottom, state: state).newState }

    // next point wins immediately
    let result = ScoringEngine.applyPoint(to: .top, state: state)
    #expect(result.gameWon)
    #expect(result.newState.gamesWon[.top] == 1)
}

@Test func noAdLoserCanWinAfterDeuce() {
    var state = GameState(noAd: true)
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .top, state: state).newState }
    for _ in 0..<3 { state = ScoringEngine.applyPoint(to: .bottom, state: state).newState }

    let result = ScoringEngine.applyPoint(to: .bottom, state: state)
    #expect(result.gameWon)
    #expect(result.newState.gamesWon[.bottom] == 1)
}

// MARK: - Multiple games

@Test func gamesWonAccumulate() {
    var state = GameState()

    func winGame(for side: Side) {
        for _ in 0..<4 {
            state = ScoringEngine.applyPoint(to: side, state: state).newState
        }
    }

    winGame(for: .top)
    winGame(for: .top)
    winGame(for: .bottom)

    #expect(state.gamesWon[.top] == 2)
    #expect(state.gamesWon[.bottom] == 1)
}

// MARK: - Serve box

@Test func serveBoxAlternatesEachPoint() {
    var state = GameState(server: .bottom)
    // point 0: even → bottom server → screen-right
    #expect(ScoringEngine.serveBox(in: state) == .right)
    state = ScoringEngine.applyPoint(to: .top, state: state).newState
    // point 1: odd → bottom server → screen-left
    #expect(ScoringEngine.serveBox(in: state) == .left)
}

@Test func serverSwitchesAfterGame() {
    var state = GameState(server: .bottom)
    for _ in 0..<4 {
        state = ScoringEngine.applyPoint(to: .bottom, state: state).newState
    }
    #expect(state.server == .top)
}

@Test func topServerBoxMirrored() {
    // Top server: deuce side (even points) = screen-left (their right from top)
    let state = GameState(server: .top)
    #expect(ScoringEngine.serveBox(in: state) == .left)
}

// MARK: - Straight 4-0 does not require advantage rule

@Test func straightFourPointWin() {
    var state = GameState()
    var won = false
    for _ in 0..<4 {
        let r = ScoringEngine.applyPoint(to: .bottom, state: state)
        state = r.newState
        won = r.gameWon
    }
    #expect(won)
}
