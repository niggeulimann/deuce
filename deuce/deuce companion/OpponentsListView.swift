import SwiftUI
import SwiftData

struct OpponentsListView: View {
    @Query private var matches: [MatchRecord]

    private var opponents: [String] { Analytics.opponents(matches) }

    var body: some View {
        NavigationStack {
            List {
                HeroHeader(
                    title: "Opponents",
                    imageNames: ["opponent", "opponent2"],
                    motif: "person.2.fill",
                    tint: .blue
                )
                    .heroListRow()

                if opponents.isEmpty {
                    Text(String(localized: "Assign opponents to your matches to build head-to-head records."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(opponents, id: \.self) { name in
                        NavigationLink {
                            OpponentDetailView(opponentName: name)
                        } label: {
                            OpponentRow(name: name, record: Analytics.record(vsOpponent: name, in: matches))
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

private struct OpponentRow: View {
    let name: String
    let record: Analytics.WinLoss

    var body: some View {
        HStack {
            Text(name).font(.headline)
            Spacer()
            Text("\(record.wins)–\(record.losses)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(record.wins >= record.losses ? .green : .red)
        }
        .padding(.vertical, 2)
    }
}
