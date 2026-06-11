import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.locale) private var locale
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
                    Text(L10n.string("Play some matches to see your statistics.", locale: locale))
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
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    stat(L10n.string("Played", locale: locale), "\(record.total)", .primary)
                    stat(L10n.string("Win rate", locale: locale), Format.percent(record.winRate), .blue)
                    stat(L10n.string("Streak", locale: locale), streakLabel, streak >= 0 ? .green : .red)
                }
                .frame(minHeight: 72)
                .overlay {
                    GeometryReader { proxy in
                        verticalRule
                            .position(x: proxy.size.width / 3, y: proxy.size.height / 2)
                        verticalRule
                            .position(x: proxy.size.width * 2 / 3, y: proxy.size.height / 2)
                    }
                }

                Divider()

                HStack(spacing: 0) {
                    stat(L10n.string("Wins", locale: locale), "\(record.wins)", .green)
                    stat(L10n.string("Losses", locale: locale), "\(record.losses)", .red)
                }
                .frame(minHeight: 72)
                .overlay {
                    GeometryReader { proxy in
                        verticalRule
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
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
            Section(L10n.string("Win rate over time", locale: locale)) {
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
            Section(L10n.string("Surfaces", locale: locale)) {
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
            Section(L10n.string("Match Dynamics", locale: locale)) {
                if let avgDuration {
                    LabeledContent(L10n.string("Avg. duration", locale: locale), value: Format.duration(avgDuration))
                }
                if let longest {
                    LabeledContent(L10n.string("Longest rally", locale: locale), value: Format.duration(longest))
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

    private var verticalRule: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.22))
            .frame(width: 1)
            .padding(.vertical, 8)
    }

    private func surfaceLabel(_ raw: String) -> String {
        CourtSurface(rawValue: raw)?.label(locale: locale) ?? raw
    }

    private func surfaceColor(_ raw: String) -> Color {
        CourtSurface(rawValue: raw)?.colorTop ?? .gray
    }
}
