import SwiftUI

struct StartView: View {
    @State private var matchActive = false
    @State private var firstServer: Side = .bottom
    @State private var noAd = false
    @State private var surface: CourtSurface = .clay

    var body: some View {
        if matchActive {
            MatchView(
                isActive: $matchActive,
                vm: MatchViewModel(server: firstServer, noAd: noAd, surface: surface)
            )
        } else {
            startScreen
        }
    }

    private var startScreen: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Deuce")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .padding(.top, 4)

                // Serve
                VStack(spacing: 6) {
                    Text("Aufschlag")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        choiceButton(label: "Du",     selected: firstServer == .bottom) { firstServer = .bottom }
                        choiceButton(label: "Gegner", selected: firstServer == .top)    { firstServer = .top }
                    }
                }

                // Surface
                VStack(spacing: 6) {
                    Text("Belag")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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

                Button {
                    matchActive = true
                } label: {
                    Text("Spielen")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 10)
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
                .font(.system(size: 13, weight: selected ? .bold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selected ? color.opacity(0.85) : Color(white: 0.22))
                .foregroundStyle(selected ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
