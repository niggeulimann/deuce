import SwiftUI

struct StartView: View {
    @State private var matchActive   = false
    @State private var showHistory   = false
    @State private var firstServer: Side = .bottom
    @State private var noAd        = false
    @State private var surface: CourtSurface = .clay
    @State private var gamesPerSet = 6
    @State private var setsToWin   = 2   // best of 3

    var body: some View {
        if matchActive {
            MatchView(
                isActive: $matchActive,
                vm: MatchViewModel(
                    server: firstServer, noAd: noAd,
                    gamesPerSet: gamesPerSet, setsToWin: setsToWin,
                    surface: surface
                )
            )
        } else {
            startScreen
        }
    }

    private var startScreen: some View {
        ScrollView {

            VStack(spacing: 12) {

                Button { matchActive = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tennisball.fill").font(.system(size: 18))
                        Text("Spielen").font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 6)

                // Serve
                VStack(spacing: 6) {
                    sectionHeader(icon: "tennisball.fill", label: "Aufschlag")
                    HStack(spacing: 8) {
                        choiceButton(label: "Du",     selected: firstServer == .bottom) { firstServer = .bottom }
                        choiceButton(label: "Gegner", selected: firstServer == .top)    { firstServer = .top }
                    }
                }

                // Sets
                VStack(spacing: 6) {
                    sectionHeader(icon: "trophy", label: "Sätze")
                    HStack(spacing: 8) {
                        choiceButton(label: "1",        selected: setsToWin == 1) { setsToWin = 1 }
                        choiceButton(label: "Best of 3", selected: setsToWin == 2) { setsToWin = 2 }
                        choiceButton(label: "Best of 5", selected: setsToWin == 3) { setsToWin = 3 }
                    }
                }

                // Games per set
                VStack(spacing: 6) {
                    sectionHeader(icon: "number", label: "Games/Satz")
                    HStack(spacing: 8) {
                        choiceButton(label: "4", selected: gamesPerSet == 4) { gamesPerSet = 4 }
                        choiceButton(label: "6", selected: gamesPerSet == 6) { gamesPerSet = 6 }
                    }
                }

                // Surface
                VStack(spacing: 6) {
                    sectionHeader(icon: "rectangle.fill", label: "Belag")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(CourtSurface.allCases) { s in
                            choiceButton(label: s.label, selected: surface == s, color: s.colorTop) {
                                surface = s
                            }
                        }
                    }
                }

                Toggle("No-Ad", isOn: $noAd)
                    .font(.footnote)

                Button { showHistory = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13))
                        Text("Verlauf")
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 10)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
    }

    private func sectionHeader(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func choiceButton(
        label: String,
        selected: Bool,
        color: Color = .yellow,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selected ? color.opacity(0.85) : Color(white: 0.22))
                .foregroundStyle(selected ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
