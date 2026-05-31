import Testing
@testable import Deuce

// MARK: - Helpers

private func applyPoint(_ side: Side, _ state: GameState) -> GameState {
    ScoringEngine.applyPoint(to: side, state: state).newState
}

private func winGame(for side: Side, state: GameState) -> GameState {
    var s = state
    for _ in 0..<4 { s = applyPoint(side, s) }
    return s
}

private func winSet(for side: Side, state: GameState) -> GameState {
    var s = state
    for _ in 0..<state.gamesPerSet { s = winGame(for: side, state: s) }
    return s
}

// MARK: - Basic point progression

@Test func loveToGame() {
    var state = GameState()
    var gameWon = false
    for _ in 0..<4 {
        let r = ScoringEngine.applyPoint(to: .top, state: state)
        state = r.newState; gameWon = r.gameWon
    }
    #expect(gameWon)
    #expect(state.gamesWon[.top] == 1)
    #expect(state.points[.top] == 0)
}

@Test func scoreLabelsProgression() {
    var state = GameState()
    for label in ["0","15","30","40"] {
        #expect(ScoringEngine.scoreLabel(for: .top, in: state) == label)
        state = applyPoint(.top, state)
    }
}

// MARK: - Deuce / Advantage

@Test func reachDeuce() {
    var s = GameState()
    for _ in 0..<3 { s = applyPoint(.top, s) }
    for _ in 0..<3 { s = applyPoint(.bottom, s) }
    #expect(ScoringEngine.scoreLabel(for: .top, in: s) == "Deuce")
}

@Test func advantageAndBackToDeuce() {
    var s = GameState()
    for _ in 0..<3 { s = applyPoint(.top, s) }
    for _ in 0..<3 { s = applyPoint(.bottom, s) }
    s = applyPoint(.top, s)
    #expect(ScoringEngine.scoreLabel(for: .top, in: s) == "Ad")
    s = applyPoint(.bottom, s)
    #expect(ScoringEngine.scoreLabel(for: .top, in: s) == "Deuce")
}

@Test func winFromAdvantage() {
    var s = GameState()
    for _ in 0..<3 { s = applyPoint(.top, s) }
    for _ in 0..<3 { s = applyPoint(.bottom, s) }
    s = applyPoint(.top, s)
    let r = ScoringEngine.applyPoint(to: .top, state: s)
    #expect(r.gameWon)
    #expect(r.newState.gamesWon[.top] == 1)
}

@Test func cannotWinFromDeuceWithOnePoint() {
    var s = GameState()
    for _ in 0..<3 { s = applyPoint(.top, s) }
    for _ in 0..<3 { s = applyPoint(.bottom, s) }
    #expect(!ScoringEngine.applyPoint(to: .top, state: s).gameWon)
}

// MARK: - No-Ad

@Test func noAdWinOnFifthPoint() {
    var s = GameState(noAd: true)
    for _ in 0..<3 { s = applyPoint(.top, s) }
    for _ in 0..<3 { s = applyPoint(.bottom, s) }
    let r = ScoringEngine.applyPoint(to: .top, state: s)
    #expect(r.gameWon)
    #expect(r.newState.gamesWon[.top] == 1)
}

@Test func noAdLoserCanWinAfterDeuce() {
    var s = GameState(noAd: true)
    for _ in 0..<3 { s = applyPoint(.top, s) }
    for _ in 0..<3 { s = applyPoint(.bottom, s) }
    let r = ScoringEngine.applyPoint(to: .bottom, state: s)
    #expect(r.gameWon)
    #expect(r.newState.gamesWon[.bottom] == 1)
}

// MARK: - Multiple games

@Test func gamesWonAccumulate() {
    var s = GameState()
    s = winGame(for: .top, state: s)
    s = winGame(for: .top, state: s)
    s = winGame(for: .bottom, state: s)
    #expect(s.gamesWon[.top] == 2)
    #expect(s.gamesWon[.bottom] == 1)
}

@Test func straightFourPointWin() {
    var s = GameState(); var won = false
    for _ in 0..<4 { let r = ScoringEngine.applyPoint(to: .bottom, state: s); s = r.newState; won = r.gameWon }
    #expect(won)
}

// MARK: - Serve box

@Test func serveBoxAlternatesEachPoint() {
    var s = GameState(server: .bottom)
    #expect(ScoringEngine.serveBox(in: s) == .right)
    s = applyPoint(.top, s)
    #expect(ScoringEngine.serveBox(in: s) == .left)
}

@Test func serverSwitchesAfterGame() {
    var s = GameState(server: .bottom)
    s = winGame(for: .bottom, state: s)
    #expect(s.server == .top)
}

@Test func topServerBoxMirrored() {
    #expect(ScoringEngine.serveBox(in: GameState(server: .top)) == .left)
}

// MARK: - Sets

@Test func setWonAfterSixGames() {
    var s = GameState(gamesPerSet: 6)
    for _ in 0..<6 { s = winGame(for: .top, state: s) }
    #expect(s.setsWon[.top] == 1)
    #expect(s.gamesWon[.top] == 0)   // games reset after set
    #expect(s.setHistory.count == 1)
    #expect(s.setHistory[0].top == 6)
}

@Test func setRequiresTwoGameLead() {
    var s = GameState(gamesPerSet: 6)
    // reach 6-5
    for _ in 0..<6 { s = winGame(for: .top,    state: s) }
    for _ in 0..<5 { s = winGame(for: .bottom, state: s) }
    // top has 6, bottom has 5 – but set already won at 6-0. Reset to 6-5 manually
    s.setsWon = [.top: 0, .bottom: 0]
    s.setHistory = []
    s.gamesWon = [.top: 6, .bottom: 5]
    // bottom wins one more → 6-6, no set won yet
    s = winGame(for: .bottom, state: s)
    #expect(s.setsWon[.top] == 0)
    #expect(s.setsWon[.bottom] == 0)
    // top wins → 7-6, set won
    s = winGame(for: .top, state: s)
    #expect(s.setsWon[.top] == 1)
}

@Test func multipleSetHistory() {
    var s = GameState(gamesPerSet: 6, setsToWin: 2)
    s = winSet(for: .top,    state: s)
    s = winSet(for: .bottom, state: s)
    #expect(s.setsWon[.top]    == 1)
    #expect(s.setsWon[.bottom] == 1)
    #expect(s.setHistory.count == 2)
}

@Test func setWonFlagReturnedCorrectly() {
    var s = GameState(gamesPerSet: 6)
    // win 5 games – no set won yet
    for _ in 0..<5 {
        let r = ScoringEngine.applyPoint(to: .top, state: s)
        // win the game
        var gs = s
        for _ in 0..<4 { gs = applyPoint(.top, gs) }
        #expect(!ScoringEngine.applyPoint(to: .top, state: s).setWon || gs.gamesWon[.top]! < 6)
        s = gs
    }
    // 6th game: last point should return setWon = true
    var gs = s
    for _ in 0..<3 { gs = applyPoint(.top, gs) }
    let final = ScoringEngine.applyPoint(to: .top, state: gs)
    #expect(final.setWon)
}
