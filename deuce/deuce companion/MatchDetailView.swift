import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Bindable var record: MatchRecord
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KnownOpponent.lastPlayed, order: .reverse) private var knownOpponents: [KnownOpponent]

    @State private var newOpponent = ""

    var body: some View {
        Form {
            // Result header
            Section {
                HStack {
                    resultBadge
                    Spacer()
                    Text("\(record.setsBottom):\(record.setsTop)")
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                }
                LabeledContent(String(localized: "Date")) {
                    Text(record.date, format: .dateTime.day().month().year().hour().minute())
                }
                if let surface = CourtSurface(rawValue: record.surface) {
                    LabeledContent(String(localized: "Surface"), value: surface.label)
                }
                LabeledContent(String(localized: "Mode"), value: modeLabel)
            }

            // Set table
            Section(String(localized: "Sets")) {
                setTable
            }

            // Opponent
            Section(String(localized: "Opponent")) {
                if !knownOpponents.isEmpty {
                    Picker(String(localized: "Opponent"), selection: opponentBinding) {
                        Text(String(localized: "Unknown opponent")).tag("")
                        ForEach(knownOpponents) { o in
                            Text(o.name).tag(o.name)
                        }
                    }
                }
                HStack {
                    TextField(String(localized: "New opponent"), text: $newOpponent)
                    Button(String(localized: "Add")) { addOpponent() }
                        .disabled(newOpponent.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Notes
            Section(String(localized: "Notes")) {
                TextField(String(localized: "Notes"), text: $record.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Dynamics
            if hasDynamics {
                Section(String(localized: "Match Dynamics")) {
                    if let w = Analytics.warmup(record) {
                        LabeledContent(String(localized: "Warmup"), value: Format.duration(w))
                    }
                    if let d = Analytics.duration(record) {
                        LabeledContent(String(localized: "Duration"), value: Format.duration(d))
                    }
                    if let lr = Analytics.longestRally(record) {
                        LabeledContent(String(localized: "Longest rally"), value: Format.duration(lr))
                    }
                    if let ar = Analytics.averageRally(record) {
                        LabeledContent(String(localized: "Avg. rally"), value: Format.duration(ar))
                    }
                    LabeledContent(String(localized: "Points"), value: "\(record.pointOffsets.count)")
                }
            }
        }
        .navigationTitle(record.opponentName.isEmpty
                         ? String(localized: "Match")
                         : record.opponentName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            syncRecord()
        }
    }

    // MARK: - Set table

    private var setTable: some View {
        let sets = allSetScores
        return Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            GridRow {
                Text("").gridColumnAlignment(.leading)
                ForEach(0..<sets.count, id: \.self) { i in
                    Text(String(localized: "Set \(i + 1)"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            GridRow {
                Text(String(localized: "You")).font(.subheadline.weight(.medium))
                ForEach(0..<sets.count, id: \.self) { i in
                    Text("\(sets[i].bottom)").font(.body.monospacedDigit().weight(.semibold))
                }
            }
            GridRow {
                Text(String(localized: "Opponent")).font(.subheadline.weight(.medium))
                ForEach(0..<sets.count, id: \.self) { i in
                    Text("\(sets[i].top)").font(.body.monospacedDigit())
                }
            }
        }
    }

    private var allSetScores: [(top: Int, bottom: Int)] {
        var sets = zip(record.setScoresTop, record.setScoresBottom).map { (top: $0.0, bottom: $0.1) }
        let hasCurrent = record.currentGamesTop > 0 || record.currentGamesBottom > 0
        if !record.isComplete && hasCurrent {
            sets.append((top: record.currentGamesTop, bottom: record.currentGamesBottom))
        }
        return sets
    }

    // MARK: - Opponent editing

    private var opponentBinding: Binding<String> {
        Binding(
            get: { record.opponentName },
            set: { setOpponent($0) }
        )
    }

    private func setOpponent(_ name: String) {
        record.opponentName = name
        if !name.isEmpty {
            if let existing = knownOpponents.first(where: { $0.name == name }) {
                existing.lastPlayed = .now
            } else {
                modelContext.insert(KnownOpponent(name: name))
            }
        }
        syncRecord()
    }

    private func addOpponent() {
        let name = newOpponent.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        setOpponent(name)
        newOpponent = ""
    }

    private func syncRecord() {
        record.markModified()
        try? modelContext.save()
        PhoneSyncManager.shared.send(record)
    }

    // MARK: - Derived

    private var hasDynamics: Bool { !record.pointOffsets.isEmpty }

    private var resultBadge: some View {
        Label(
            record.isComplete ? (record.didWin ? String(localized: "Won") : String(localized: "Lost"))
                              : String(localized: "Abandoned"),
            systemImage: record.isComplete ? (record.didWin ? "trophy.fill" : "xmark") : "pause.circle"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(record.isComplete ? (record.didWin ? .green : .red) : .orange)
    }

    private var modeLabel: String {
        record.setsToWin == 1 ? String(localized: "1 Set")
            : String(localized: "Best of \(record.setsToWin * 2 - 1)")
    }
}
