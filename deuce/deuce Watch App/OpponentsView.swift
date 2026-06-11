import SwiftUI
import SwiftData

struct OpponentsView: View {
    @Query private var matches: [MatchRecord]

    private var opponents: [String] {
        Analytics.opponents(matches)
    }

    var body: some View {
        Group {
            if opponents.isEmpty {
                ContentUnavailableView(
                    "No opponents yet",
                    systemImage: "person.2",
                    description: Text("Assign opponents to matches to see them here.")
                )
            } else {
                List(opponents, id: \.self) { name in
                    NavigationLink {
                        WatchOpponentDetailView(
                            opponentName: name,
                            allMatches: matches
                        )
                    } label: {
                        OpponentRow(
                            name: name,
                            record: Analytics.record(vsOpponent: name, in: matches)
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "Opponents"))
    }
}

private struct OpponentRow: View {
    let name: String
    let record: Analytics.WinLoss

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(record.total) \(String(localized: "Matches"))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.wins)–\(record.losses)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(record.wins >= record.losses ? .green : .red)
        }
    }
}

private struct WatchOpponentDetailView: View {
    let opponentName: String
    let allMatches: [MatchRecord]

    private var matches: [MatchRecord] {
        allMatches
            .filter { $0.isVisible && $0.opponentName == opponentName }
            .sorted { $0.date > $1.date }
    }

    private var record: Analytics.WinLoss {
        Analytics.record(matches)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    stat(String(localized: "Wins"), value: "\(record.wins)", color: .green)
                    Divider()
                    stat(String(localized: "Losses"), value: "\(record.losses)", color: .red)
                    Divider()
                    stat(
                        String(localized: "Win rate"),
                        value: Format.percent(record.winRate),
                        color: .blue
                    )
                }
                .frame(minHeight: 54)
            }

            Section(String(localized: "History")) {
                ForEach(matches) { match in
                    NavigationLink {
                        MatchDetailView(record: match)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(indicatorColor(for: match))
                                .frame(width: 7, height: 7)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(match.date, style: .date)
                                    .font(.system(size: 11, weight: .medium))
                                Text(match.isComplete
                                     ? (match.didWin
                                        ? String(localized: "Won")
                                        : String(localized: "Lost"))
                                     : String(localized: "Abandoned"))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(match.setsBottom):\(match.setsTop)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                    }
                }
            }
        }
        .navigationTitle(opponentName)
    }

    private func stat(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func indicatorColor(for match: MatchRecord) -> Color {
        guard match.isComplete else { return .gray }
        return match.didWin ? .green : .red
    }
}
