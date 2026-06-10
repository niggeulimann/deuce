import SwiftUI
import SwiftData
import Charts

struct OpponentDetailView: View {
    let opponentName: String
    @Query private var allMatches: [MatchRecord]

    private var matches: [MatchRecord] {
        allMatches
            .filter { $0.isVisible && $0.opponentName == opponentName }
            .sorted { $0.date > $1.date }
    }
    private var record: Analytics.WinLoss { Analytics.record(matches) }

    var body: some View {
        List {
            // H2H summary
            Section {
                HStack {
                    stat(title: L10n.string("Wins"),   value: "\(record.wins)",   color: .green)
                    Divider()
                    stat(title: L10n.string("Losses"), value: "\(record.losses)", color: .red)
                    Divider()
                    stat(title: L10n.string("Win rate"), value: Format.percent(record.winRate), color: .blue)
                }
                .frame(maxWidth: .infinity)
            }

            // Win-rate trend
            if record.total >= 2 {
                Section(L10n.string("Win rate trend")) {
                    Chart(Analytics.winRateTrend(matches), id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Win rate", point.winRate)
                        )
                        .interpolationMethod(.monotone)
                    }
                    .chartYScale(domain: 0...1)
                    .frame(height: 160)
                }
            }

            // Match list
            Section(L10n.string("Matches")) {
                ForEach(matches) { match in
                    NavigationLink {
                        MatchDetailView(record: match)
                    } label: {
                        HStack {
                            Circle()
                                .fill(match.isComplete ? (match.didWin ? .green : .red) : .gray)
                                .frame(width: 8, height: 8)
                            Text(match.date, format: .dateTime.day().month().year())
                                .font(.subheadline)
                            Spacer()
                            Text("\(match.setsBottom):\(match.setsTop)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                        }
                    }
                }
            }
        }
        .navigationTitle(opponentName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
