import Testing
import Foundation
@testable import deuce_Watch_App

// MARK: - Builder

private func match(
    opponent: String = "",
    date: Date = .now,
    didWin: Bool = true,
    isComplete: Bool = true,
    surface: String = "clay",
    setsTop: Int = 0,
    setsBottom: Int = 2,
    firstPointOffset: Double = -1,
    pointOffsets: [Double] = []
) -> MatchRecord {
    MatchRecord(
        date: date,
        surface: surface,
        noAd: false,
        gamesPerSet: 6,
        setsToWin: 2,
        isComplete: isComplete,
        setsTop: setsTop,
        setsBottom: setsBottom,
        setScoresTop: [],
        setScoresBottom: [],
        currentGamesTop: 0,
        currentGamesBottom: 0,
        currentPointsTop: 0,
        currentPointsBottom: 0,
        didWin: didWin,
        opponentName: opponent,
        firstPointOffset: firstPointOffset,
        pointOffsets: pointOffsets
    )
}

private func day(_ n: Int) -> Date {
    Date(timeIntervalSince1970: TimeInterval(n) * 86_400)
}

// MARK: - Win / loss

@Test func recordCountsOnlyCompleted() {
    let ms = [
        match(didWin: true,  isComplete: true),
        match(didWin: false, isComplete: true),
        match(didWin: true,  isComplete: true),
        match(didWin: false, isComplete: false)   // abandoned → ignored
    ]
    let r = Analytics.record(ms)
    #expect(r.wins == 2)
    #expect(r.losses == 1)
    #expect(r.total == 3)
}

@Test func winRateComputed() {
    let ms = [match(didWin: true), match(didWin: true), match(didWin: false), match(didWin: false)]
    #expect(Analytics.record(ms).winRate == 0.5)
}

@Test func headToHeadFiltersByOpponent() {
    let ms = [
        match(opponent: "Alex", didWin: true),
        match(opponent: "Alex", didWin: false),
        match(opponent: "Sam",  didWin: true)
    ]
    let r = Analytics.record(vsOpponent: "Alex", in: ms)
    #expect(r.wins == 1)
    #expect(r.losses == 1)
}

// MARK: - Streak

@Test func currentStreakPositiveForWins() {
    let ms = [
        match(date: day(1), didWin: false),
        match(date: day(2), didWin: true),
        match(date: day(3), didWin: true)
    ]
    #expect(Analytics.currentStreak(ms) == 2)
}

@Test func currentStreakNegativeForLosses() {
    let ms = [
        match(date: day(1), didWin: true),
        match(date: day(2), didWin: false),
        match(date: day(3), didWin: false)
    ]
    #expect(Analytics.currentStreak(ms) == -2)
}

@Test func currentStreakEmpty() {
    #expect(Analytics.currentStreak([]) == 0)
}

// MARK: - Opponents & surfaces

@Test func opponentsSortedByRecency() {
    let ms = [
        match(opponent: "Alex", date: day(1)),
        match(opponent: "Sam",  date: day(3)),
        match(opponent: "Alex", date: day(2)),
        match(opponent: "",     date: day(9))   // unnamed → excluded
    ]
    #expect(Analytics.opponents(ms) == ["Sam", "Alex"])
}

@Test func surfaceBreakdownCounts() {
    let ms = [match(surface: "clay"), match(surface: "clay"), match(surface: "grass")]
    let b = Analytics.surfaceBreakdown(ms)
    #expect(b.first?.surface == "clay")
    #expect(b.first?.count == 2)
}

// MARK: - Trend

@Test func winRateTrendIsCumulative() {
    let ms = [
        match(date: day(1), didWin: true),
        match(date: day(2), didWin: false),
        match(date: day(3), didWin: true)
    ]
    let t = Analytics.winRateTrend(ms)
    #expect(t.count == 3)
    #expect(t[0].winRate == 1.0)
    #expect(t[1].winRate == 0.5)
    #expect(abs(t[2].winRate - 2.0/3.0) < 0.0001)
}

// MARK: - Dynamics

@Test func warmupReturnsFirstPointOffset() {
    let m = match(firstPointOffset: 95)
    #expect(Analytics.warmup(m) == 95)
    #expect(Analytics.warmup(match(firstPointOffset: -1)) == nil)
}

@Test func durationIsLastPointOffset() {
    let m = match(pointOffsets: [100, 130, 210])
    #expect(Analytics.duration(m) == 210)
}

@Test func rallyGapsAndLongest() {
    // gaps: 30, 80, 10  → longest 80, avg 40
    let m = match(pointOffsets: [100, 130, 210, 220])
    #expect(Analytics.rallyGaps(m) == [30, 80, 10])
    #expect(Analytics.longestRally(m) == 80)
    #expect(Analytics.averageRally(m) == 40)
}

@Test func longestRallyEverAcrossMatches() {
    let ms = [
        match(pointOffsets: [0, 20, 30]),    // gaps 20, 10
        match(pointOffsets: [0, 5, 100])     // gaps 5, 95
    ]
    #expect(Analytics.longestRallyEver(ms) == 95)
}
