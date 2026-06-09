import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(
        filter: #Predicate<MatchRecord> { $0.isDeleted == false },
        sort: \MatchRecord.date,
        order: .reverse
    ) private var records: [MatchRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No matches yet",
                        systemImage: "tennisball",
                        description: Text("Played matches appear here.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            NavigationLink(destination: MatchDetailView(record: record)) {
                                MatchRowView(record: record)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                let record = records[i]
                                record.markDeleted()
                                sync(record)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(String(localized: "History"))
        }
    }

    private func sync(_ record: MatchRecord) {
        try? modelContext.save()
        WatchSyncManager.shared.send(MatchRecordDTO(record))
    }
}

// MARK: - Row

private struct MatchRowView: View {
    let record: MatchRecord

    var body: some View {
        HStack(spacing: 8) {
            // Won / lost / incomplete indicator
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(record.date, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(setsLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(surfaceEmoji)
                .font(.system(size: 13))
        }
        .padding(.vertical, 2)
    }

    private var title: String {
        record.opponentName.isEmpty ? String(localized: "Match") : record.opponentName
    }

    private var indicatorColor: Color {
        guard record.isComplete else { return .gray.opacity(0.6) }
        return record.didWin ? .green : .red.opacity(0.7)
    }

    private var setsLabel: String {
        let b = record.setsBottom
        let t = record.setsTop
        let tag = record.isComplete ? "" : " •"
        return "\(b):\(t)\(tag)"
    }

    private var surfaceEmoji: String {
        switch record.surface {
        case "clay":    return "🟤"
        case "grass":   return "🟢"
        case "hard":    return "🔵"
        case "carpet":  return "🟣"
        default:        return "⬜"
        }
    }
}

// MARK: - Detail

struct MatchDetailView: View {
    let record: MatchRecord
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KnownOpponent.lastPlayed, order: .reverse) private var knownOpponents: [KnownOpponent]

    @State private var showOpponentPicker = false
    @State private var newOpponentName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 2) {
                    Text(record.date, style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(record.date, style: .time)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if !record.isComplete {
                        Text("Abandoned")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }

                // Opponent row
                Button { showOpponentPicker = true } label: {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(record.opponentName.isEmpty
                             ? String(localized: "Add opponent")
                             : record.opponentName)
                            .font(.system(size: 12))
                            .foregroundStyle(record.opponentName.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                // Set table
                setTable

                // Settings info
                VStack(spacing: 4) {
                    infoRow(label: String(localized: "Surface"), value: surfaceName)
                    infoRow(label: String(localized: "Mode"),    value: modeLabel)
                    if record.noAd {
                        infoRow(label: String(localized: "No-Ad"), value: "✓")
                    }
                    if record.firstPointOffset > 0 {
                        infoRow(label: String(localized: "Warmup"),
                                value: formatDuration(record.firstPointOffset))
                    }
                    if !record.pointOffsets.isEmpty {
                        infoRow(label: String(localized: "Points"),
                                value: "\(record.pointOffsets.count)")
                    }
                    if record.pointOffsets.count > 1 {
                        let gaps = zip(record.pointOffsets, record.pointOffsets.dropFirst()).map { $1 - $0 }
                        let average = gaps.reduce(0, +) / Double(gaps.count)
                        infoRow(label: String(localized: "Average rally"),
                                value: formatDuration(average))
                        if let longest = gaps.max() {
                            infoRow(label: String(localized: "Longest rally"),
                                    value: formatDuration(longest))
                        }
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .navigationTitle(record.didWin && record.isComplete ? String(localized: "Won 🏆") : String(localized: "Match"))
        .sheet(isPresented: $showOpponentPicker) {
            opponentPickerSheet
        }
    }

    // MARK: Opponent picker sheet

    private var opponentPickerSheet: some View {
        NavigationStack {
            List {
                // Text input for new name
                HStack {
                    TextField(String(localized: "New opponent"), text: $newOpponentName)
                        .font(.system(size: 13))
                    if !newOpponentName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            saveOpponent(newOpponentName.trimmingCharacters(in: .whitespaces))
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Known opponents
                ForEach(knownOpponents) { opponent in
                    Button {
                        saveOpponent(opponent.name)
                    } label: {
                        HStack {
                            Text(opponent.name).font(.system(size: 13))
                            Spacer()
                            if record.opponentName == opponent.name {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Clear
                if !record.opponentName.isEmpty {
                    Button(role: .destructive) {
                        record.opponentName = ""
                        sync(record)
                        showOpponentPicker = false
                    } label: {
                        Text(String(localized: "Remove opponent"))
                            .font(.system(size: 12))
                    }
                }
            }
            .navigationTitle(String(localized: "Opponent"))
#if os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    private func saveOpponent(_ name: String) {
        record.opponentName = name
        // Upsert into known opponents
        if let existing = knownOpponents.first(where: { $0.name == name }) {
            existing.lastPlayed = .now
        } else {
            modelContext.insert(KnownOpponent(name: name))
        }
        newOpponentName = ""
        sync(record)
        showOpponentPicker = false
    }

    private func sync(_ record: MatchRecord) {
        record.markModified()
        try? modelContext.save()
        WatchSyncManager.shared.send(MatchRecordDTO(record))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        return "\(s / 60)m \(s % 60)s"
    }

    // MARK: Set table

    private var setTable: some View {
        let allSets = allSetScores

        return VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 44, alignment: .leading)
                ForEach(0..<allSets.count, id: \.self) { i in
                    Text(String(localized: "Set \(i + 1)"))
                        .font(.system(size: 10, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            Divider()

            playerRow(label: String(localized: "Opponent"),
                      scores: allSets.map(\.top),
                      sets: record.setsTop)

            Divider()

            playerRow(label: String(localized: "You"),
                      scores: allSets.map(\.bottom),
                      sets: record.setsBottom)
        }
        .padding(8)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func playerRow(label: String, scores: [Int], sets: Int) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 44, alignment: .leading)
            ForEach(0..<scores.count, id: \.self) { i in
                Text("\(scores[i])")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            Text("\(sets)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.yellow)
                .frame(width: 22)
        }
        .padding(.vertical, 6)
    }

    // Combine finished sets + current (incomplete) set if match isn't complete
    private var allSetScores: [(top: Int, bottom: Int)] {
        var sets = zip(record.setScoresTop, record.setScoresBottom).map {
            (top: $0.0, bottom: $0.1)
        }
        let hasCurrentGames = record.currentGamesTop > 0 || record.currentGamesBottom > 0
        if !record.isComplete && hasCurrentGames {
            sets.append((top: record.currentGamesTop, bottom: record.currentGamesBottom))
        }
        return sets
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    private var surfaceName: String {
        CourtSurface(rawValue: record.surface)?.label ?? record.surface
    }

    private var modeLabel: String {
        record.setsToWin == 1 ? String(localized: "1 Set")
            : String(localized: "Best of \(record.setsToWin * 2 - 1)")
    }
}
