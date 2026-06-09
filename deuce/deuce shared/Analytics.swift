import Foundation

/// Pure, UI-independent analytics over a collection of `MatchRecord`s.
/// Everything here is deterministic and unit-testable.
enum Analytics {

    // MARK: - Win / loss

    struct WinLoss: Equatable {
        var wins: Int
        var losses: Int
        var total: Int { wins + losses }
        var winRate: Double { total == 0 ? 0 : Double(wins) / Double(total) }
    }

    /// Win/loss over completed matches only.
    static func record(_ matches: [MatchRecord]) -> WinLoss {
        var w = 0, l = 0
        for m in matches where m.isVisible && m.isComplete {
            if m.didWin { w += 1 } else { l += 1 }
        }
        return WinLoss(wins: w, losses: l)
    }

    /// Win/loss against a specific opponent (completed matches only).
    static func record(vsOpponent name: String, in matches: [MatchRecord]) -> WinLoss {
        record(matches.filter { $0.opponentName == name })
    }

    /// Signed streak from the most recent completed matches:
    /// positive = consecutive wins, negative = consecutive losses, 0 = none.
    static func currentStreak(_ matches: [MatchRecord]) -> Int {
        let completed = matches.filter { $0.isVisible && $0.isComplete }.sorted { $0.date < $1.date }
        guard let last = completed.last else { return 0 }
        let wantWin = last.didWin
        var streak = 0
        for m in completed.reversed() {
            if m.didWin == wantWin { streak += 1 } else { break }
        }
        return wantWin ? streak : -streak
    }

    // MARK: - Breakdowns

    /// Distinct, named opponents sorted by most-recently played.
    static func opponents(_ matches: [MatchRecord]) -> [String] {
        var lastPlayed: [String: Date] = [:]
        for m in matches where m.isVisible && !m.opponentName.isEmpty {
            let d = lastPlayed[m.opponentName]
            if d == nil || m.date > d! { lastPlayed[m.opponentName] = m.date }
        }
        return lastPlayed.keys.sorted { lastPlayed[$0]! > lastPlayed[$1]! }
    }

    /// Match count per surface (rawValue), descending.
    static func surfaceBreakdown(_ matches: [MatchRecord]) -> [(surface: String, count: Int)] {
        var counts: [String: Int] = [:]
        for m in matches where m.isVisible { counts[m.surface, default: 0] += 1 }
        return counts.map { (surface: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Cumulative win-rate after each completed match, oldest → newest (for trend charts).
    static func winRateTrend(_ matches: [MatchRecord]) -> [(date: Date, winRate: Double)] {
        let completed = matches.filter { $0.isVisible && $0.isComplete }.sorted { $0.date < $1.date }
        var wins = 0, total = 0
        return completed.map { m in
            total += 1
            if m.didWin { wins += 1 }
            return (date: m.date, winRate: Double(wins) / Double(total))
        }
    }

    // MARK: - Per-match dynamics (from timestamps)

    /// Elapsed time to the last point = match duration.
    static func duration(_ m: MatchRecord) -> TimeInterval? {
        m.pointOffsets.last
    }

    /// Warmup time = time to the first point. Nil if not recorded.
    static func warmup(_ m: MatchRecord) -> TimeInterval? {
        m.firstPointOffset >= 0 ? m.firstPointOffset : nil
    }

    /// Gaps between consecutive points (approximation of rally + between-point time).
    static func rallyGaps(_ m: MatchRecord) -> [TimeInterval] {
        guard m.pointOffsets.count > 1 else { return [] }
        return zip(m.pointOffsets, m.pointOffsets.dropFirst()).map { $1 - $0 }
    }

    static func longestRally(_ m: MatchRecord) -> TimeInterval? {
        rallyGaps(m).max()
    }

    static func averageRally(_ m: MatchRecord) -> TimeInterval? {
        let gaps = rallyGaps(m)
        guard !gaps.isEmpty else { return nil }
        return gaps.reduce(0, +) / Double(gaps.count)
    }

    // MARK: - Aggregate dynamics

    static func longestRallyEver(_ matches: [MatchRecord]) -> TimeInterval? {
        matches.filter(\.isVisible).compactMap(longestRally).max()
    }

    static func averageDuration(_ matches: [MatchRecord]) -> TimeInterval? {
        let ds = matches.filter(\.isVisible).compactMap(duration)
        guard !ds.isEmpty else { return nil }
        return ds.reduce(0, +) / Double(ds.count)
    }
}
