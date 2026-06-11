import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.locale) private var locale
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
                LabeledContent(L10n.string("Date", locale: locale)) {
                    Text(record.date, format: .dateTime.day().month().year().hour().minute())
                }
                if let surface = CourtSurface(rawValue: record.surface) {
                    LabeledContent(
                        L10n.string("Surface", locale: locale),
                        value: surface.label(locale: locale)
                    )
                }
                LabeledContent(L10n.string("Mode", locale: locale), value: modeLabel)
            }

            // Set table
            Section(L10n.string("Sets", locale: locale)) {
                setTable
            }

            // Opponent
            Section(L10n.string("Opponent", locale: locale)) {
                if !knownOpponents.isEmpty {
                    Picker(L10n.string("Opponent", locale: locale), selection: opponentBinding) {
                        Text(L10n.string("Unknown opponent", locale: locale)).tag("")
                        ForEach(knownOpponents) { o in
                            Text(o.name).tag(o.name)
                        }
                    }
                }
                HStack {
                    TextField(L10n.string("New opponent", locale: locale), text: $newOpponent)
                    Button(L10n.string("Add", locale: locale)) { addOpponent() }
                        .disabled(newOpponent.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Notes
            Section(L10n.string("Notes", locale: locale)) {
                TextField(L10n.string("Notes", locale: locale), text: $record.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Dynamics
            if hasDynamics {
                Section(L10n.string("Match Dynamics", locale: locale)) {
                    if let w = Analytics.warmup(record) {
                        LabeledContent(L10n.string("Warmup", locale: locale), value: Format.duration(w))
                    }
                    if let d = Analytics.duration(record) {
                        LabeledContent(L10n.string("Duration", locale: locale), value: Format.duration(d))
                    }
                    if let lr = Analytics.longestRally(record) {
                        LabeledContent(L10n.string("Longest rally", locale: locale), value: Format.duration(lr))
                    }
                    if let ar = Analytics.averageRally(record) {
                        LabeledContent(L10n.string("Avg. rally", locale: locale), value: Format.duration(ar))
                    }
                    LabeledContent(L10n.string("Points", locale: locale), value: "\(record.pointOffsets.count)")
                }
            }
        }
        .navigationTitle(record.opponentName.isEmpty
                         ? L10n.string("Match", locale: locale)
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
                    Text(L10n.string("Set \(i + 1)", locale: locale))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            GridRow {
                Text(L10n.string("You", locale: locale)).font(.subheadline.weight(.medium))
                ForEach(0..<sets.count, id: \.self) { i in
                    Text("\(sets[i].bottom)").font(.body.monospacedDigit().weight(.semibold))
                }
            }
            GridRow {
                Text(L10n.string("Opponent", locale: locale)).font(.subheadline.weight(.medium))
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
            record.isComplete ? (record.didWin ? L10n.string("Won", locale: locale) : L10n.string("Lost", locale: locale))
                              : L10n.string("Abandoned", locale: locale),
            systemImage: record.isComplete ? (record.didWin ? "trophy.fill" : "xmark") : "pause.circle"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(record.isComplete ? (record.didWin ? .green : .red) : .orange)
    }

    private var modeLabel: String {
        record.setsToWin == 1 ? L10n.string("1 Set", locale: locale)
            : L10n.string("Best of \(record.setsToWin * 2 - 1)", locale: locale)
    }
}
