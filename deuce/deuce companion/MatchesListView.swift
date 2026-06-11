import SwiftUI
import SwiftData

struct MatchesListView: View {
    @Environment(\.locale) private var locale
    @Query(
        filter: #Predicate<MatchRecord> { $0.isDeleted == false },
        sort: \MatchRecord.date,
        order: .reverse
    ) private var matches: [MatchRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                HeroHeader(
                    title: "Matches",
                    imageNames: ["start", "start2"],
                    motif: "tennisball.fill",
                    tint: .green
                )
                    .heroListRow()

                if matches.isEmpty {
                    Text(L10n.string("Matches played on your watch appear here.", locale: locale))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(matches) { match in
                        NavigationLink {
                            MatchDetailView(record: match)
                        } label: {
                            MatchRow(record: match)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            let match = matches[i]
                            match.markDeleted()
                            try? modelContext.save()
                            PhoneSyncManager.shared.send(match)
                        }
                    }
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
}

private struct MatchRow: View {
    @Environment(\.locale) private var locale
    let record: MatchRecord

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.opponentName.isEmpty
                     ? L10n.string("Unknown opponent", locale: locale)
                     : record.opponentName)
                    .font(.headline)
                Text(record.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(record.setsBottom):\(record.setsTop)")
                    .font(.title3.weight(.bold).monospacedDigit())
                if let surface = CourtSurface(rawValue: record.surface) {
                    Text(surface.label(locale: locale))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var indicatorColor: Color {
        guard record.isComplete else { return .gray.opacity(0.6) }
        return record.didWin ? .green : .red
    }
}
