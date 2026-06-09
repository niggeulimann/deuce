import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var matches: [MatchRecord]

    private var record: Analytics.WinLoss { Analytics.record(matches) }
    private var streak: Int { Analytics.currentStreak(matches) }

    var body: some View {
        NavigationStack {
            List {
                HeroHeader(
                    title: "Stats",
                    imageNames: ["analyse_1", "analyse_2"],
                    motif: "chart.bar.fill",
                    tint: .orange
                )
                    .heroListRow()

                if record.total == 0 {
                    Text(String(localized: "Play some matches to see your statistics."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                        .listRowSeparator(.hidden)
                } else {
                    summarySection
                    trendSection
                    surfaceSection
                    dynamicsSection
                }
            }
            .listStyle(.plain)
            .contentMargins(.top, 0, for: .scrollContent)
            .ignoresSafeArea(edges: .top)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section {
            HStack {
                stat(String(localized: "Played"), "\(record.total)", .primary)
                Divider()
                stat(String(localized: "Win rate"), Format.percent(record.winRate), .blue)
                Divider()
                stat(String(localized: "Streak"), streakLabel, streak >= 0 ? .green : .red)
            }
            HStack {
                stat(String(localized: "Wins"),   "\(record.wins)",   .green)
                Divider()
                stat(String(localized: "Losses"), "\(record.losses)", .red)
            }
        }
    }

    private var streakLabel: String {
        if streak == 0 { return "–" }
        return streak > 0 ? "\(streak)W" : "\(-streak)L"
    }

    // MARK: - Trend

    @ViewBuilder private var trendSection: some View {
        let trend = Analytics.winRateTrend(matches)
        if trend.count >= 2 {
            Section(String(localized: "Win rate over time")) {
                Chart(trend, id: \.date) { p in
                    LineMark(x: .value("Date", p.date),
                             y: .value("Win rate", p.winRate))
                    .interpolationMethod(.monotone)
                    AreaMark(x: .value("Date", p.date),
                             y: .value("Win rate", p.winRate))
                    .foregroundStyle(.blue.opacity(0.12))
                }
                .chartYScale(domain: 0...1)
                .frame(height: 180)
            }
        }
    }

    // MARK: - Surface

    @ViewBuilder private var surfaceSection: some View {
        let breakdown = Analytics.surfaceBreakdown(matches)
        if !breakdown.isEmpty {
            Section(String(localized: "Surfaces")) {
                Chart(breakdown, id: \.surface) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Surface", surfaceLabel(item.surface))
                    )
                    .foregroundStyle(surfaceColor(item.surface))
                }
                .frame(height: CGFloat(breakdown.count) * 44 + 20)
            }
        }
    }

    // MARK: - Dynamics

    @ViewBuilder private var dynamicsSection: some View {
        let avgDuration = Analytics.averageDuration(matches)
        let longest = Analytics.longestRallyEver(matches)
        if avgDuration != nil || longest != nil {
            Section(String(localized: "Match Dynamics")) {
                if let avgDuration {
                    LabeledContent(String(localized: "Avg. duration"), value: Format.duration(avgDuration))
                }
                if let longest {
                    LabeledContent(String(localized: "Longest rally"), value: Format.duration(longest))
                }
            }
        }
    }

    // MARK: - Helpers

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func surfaceLabel(_ raw: String) -> String {
        CourtSurface(rawValue: raw)?.label ?? raw
    }

    private func surfaceColor(_ raw: String) -> Color {
        CourtSurface(rawValue: raw)?.colorTop ?? .gray
    }
}
