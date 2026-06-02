import SwiftUI
import HealthKit

struct StartView: View {
    @State private var matchActive   = false
    @State private var showHistory   = false
    @State private var firstServer: Side = .bottom
    @State private var noAd        = false
    @State private var surface: CourtSurface = .clay
    @State private var gamesPerSet = 6
    @State private var setsToWin   = 2

    @AppStorage("healthOptIn")   private var healthOptIn  = false
    @AppStorage("accentThemeKey") private var accentKey   = AccentTheme.green.rawValue
    @State private var healthManager = HealthManager()

    private var accent: Color { AccentTheme(rawValue: accentKey)?.color ?? .green }

    var body: some View {
        if matchActive {
            MatchView(
                isActive: $matchActive,
                vm: MatchViewModel(
                    server: firstServer, noAd: noAd,
                    gamesPerSet: gamesPerSet, setsToWin: setsToWin,
                    surface: surface
                ),
                healthManager: healthManager,
                healthOptIn: healthOptIn,
                accent: accent
            )
        } else {
            startScreen
                .onAppear { healthManager.checkAuthorization() }
                .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    private var startScreen: some View {
        ScrollView {
            VStack(spacing: 12) {

                // Play button
                Button { matchActive = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tennisball.fill").font(.system(size: 18))
                        Text("Play").font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(accent)
                .padding(.top, 6)

                // Serve
                VStack(spacing: 6) {
                    sectionHeader(icon: "tennis.racket", label: String(localized: "Serve"))
                    HStack(spacing: 8) {
                        outlineButton(label: String(localized: "You"),       selected: firstServer == .bottom) { firstServer = .bottom }
                        outlineButton(label: String(localized: "Opponent"),  selected: firstServer == .top)    { firstServer = .top }
                    }
                }

                // Sets
                VStack(spacing: 6) {
                    sectionHeader(icon: "trophy", label: String(localized: "Sets"))
                    HStack(spacing: 8) {
                        outlineButton(label: String(localized: "1 Set"),     selected: setsToWin == 1) { setsToWin = 1 }
                        outlineButton(label: String(localized: "Best of 3"), selected: setsToWin == 2) { setsToWin = 2 }
                        outlineButton(label: String(localized: "Best of 5"), selected: setsToWin == 3) { setsToWin = 3 }
                    }
                }

                // Games per set
                VStack(spacing: 6) {
                    sectionHeader(icon: "number", label: String(localized: "Games/Set"))
                    HStack(spacing: 8) {
                        outlineButton(label: "4", selected: gamesPerSet == 4) { gamesPerSet = 4 }
                        outlineButton(label: "6", selected: gamesPerSet == 6) { gamesPerSet = 6 }
                    }
                }

                // Surface
                VStack(spacing: 6) {
                    sectionHeader(icon: "sportscourt", label: String(localized: "Surface"))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(CourtSurface.allCases) { s in
                            choiceButton(label: s.label, selected: surface == s, color: s.colorTop) {
                                surface = s
                            }
                        }
                    }
                }

                Toggle(String(localized: "No-Ad"), isOn: $noAd)
                    .font(.footnote)

                // Health toggle
                if HKHealthStore.isHealthDataAvailable() {
                    Toggle(String(localized: "Track Workout"), isOn: $healthOptIn)
                        .font(.footnote)
                        .onChange(of: healthOptIn) { _, newValue in
                            if newValue {
                                Task { await healthManager.requestAuthorization() }
                            }
                        }
                }

                // Accent colour picker
                VStack(spacing: 6) {
                    sectionHeader(icon: "paintpalette", label: String(localized: "Accent"))
                    HStack(spacing: 10) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button { accentKey = theme.rawValue } label: {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: accentKey == theme.rawValue ? 2 : 0)
                                            .padding(1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button { showHistory = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 13))
                        Text("History").font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 10)
        }
    }

    private func sectionHeader(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(.secondary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func outlineButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .regular))
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selected ? accent.opacity(0.18) : Color.clear)
                .foregroundStyle(selected ? accent : Color.white.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? accent : Color.white.opacity(0.25),
                            lineWidth: selected ? 1.5 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func choiceButton(label: String, selected: Bool, color: Color = .yellow, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .regular))
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selected ? color.opacity(0.85) : Color(white: 0.22))
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
