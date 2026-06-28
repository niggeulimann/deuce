import SwiftUI

struct PhonePlayView: View {
    @Environment(\.locale) private var locale
    @State private var warmupViewModel: MatchViewModel?
    @State private var showingMatchSetup = false
    @State private var firstServer: Side = .bottom
    @State private var noAd = false
    @State private var surface: CourtSurface = .clay
    @State private var gamesPerSet = 6
    @State private var setsToWin = 2
    @State private var opponentName = ""
    @State private var activeMatchViewModel: MatchViewModel?
    @AppStorage("accentThemeKey") private var accentKey = AccentTheme.green.rawValue

    private var accent: Color {
        AccentTheme(rawValue: accentKey)?.color ?? .green
    }

    var body: some View {
        Group {
            if let warmupViewModel {
                warmupView(viewModel: warmupViewModel)
            } else {
                startView
            }
        }
        .sheet(isPresented: $showingMatchSetup) {
            matchSetupSheet
        }
            .fullScreenCover(item: $activeMatchViewModel, onDismiss: resetMatch) { viewModel in
                MatchView(
                    isActive: matchIsActive,
                    vm: viewModel,
                    opponentName: opponentName,
                    accent: accent
                )
            }
    }

    private var startView: some View {
        NavigationStack {
            List {
                HeroHeader(
                    title: "Play",
                    imageNames: ["start", "start2"],
                    motif: "tennisball.fill",
                    tint: .green
                )
                .heroListRow()

                VStack(spacing: 14) {
                    Text(L10n.string("Start tracking before the first point. Your warmup counts too.", locale: locale))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Button(action: startWarmup) {
                        Label(L10n.string("Start Warmup", locale: locale), systemImage: "figure.tennis")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(accent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Color.clear
                    .frame(height: 64)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .contentMargins(.top, 0, for: .scrollContent)
            .ignoresSafeArea(edges: .top)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func warmupView(viewModel: MatchViewModel) -> some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "figure.tennis")
                    .font(.system(size: 72))
                    .foregroundStyle(accent)

                VStack(spacing: 8) {
                    Text(L10n.string("Warmup", locale: locale))
                        .font(.largeTitle.bold())
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(Format.duration(context.date.timeIntervalSince(viewModel.matchStartDate)))
                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    Text(L10n.string("Tracking is running", locale: locale))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingMatchSetup = true
                } label: {
                    Label(L10n.string("Start Match", locale: locale), systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(accent)

                Button(L10n.string("Cancel Session", locale: locale), role: .destructive) {
                    resetMatch()
                }
                .padding(.bottom, 80)
            }
            .padding(.horizontal, 24)
            .navigationTitle("")
        }
    }

    private var matchSetupSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: startMatch) {
                        Label(L10n.string("Start Match", locale: locale), systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(accent)
                    .listRowBackground(Color.clear)
                }

                Section(L10n.string("Opponent", locale: locale)) {
                    TextField(
                        L10n.string("Opponent name (optional)", locale: locale),
                        text: $opponentName
                    )
                    .textInputAutocapitalization(.words)
                }

                Section(L10n.string("Serve", locale: locale)) {
                    Picker(L10n.string("First server", locale: locale), selection: $firstServer) {
                        Text(L10n.string("You", locale: locale)).tag(Side.bottom)
                        Text(L10n.string("Opponent", locale: locale)).tag(Side.top)
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.string("Match Format", locale: locale)) {
                    Picker(L10n.string("Match length", locale: locale), selection: $setsToWin) {
                        Text(L10n.string("1 Set", locale: locale)).tag(1)
                        Text(L10n.string("Best of 3", locale: locale)).tag(2)
                        Text(L10n.string("Best of 5", locale: locale)).tag(3)
                        Text(L10n.string("Open", locale: locale)).tag(0)
                    }
                    .pickerStyle(.segmented)

                    Picker(L10n.string("Games/Set", locale: locale), selection: $gamesPerSet) {
                        Text("4").tag(4)
                        Text("6").tag(6)
                    }
                    .pickerStyle(.segmented)

                    Toggle(L10n.string("No-Ad", locale: locale), isOn: $noAd)
                }

                Section(L10n.string("Surface", locale: locale)) {
                    Picker(L10n.string("Surface", locale: locale), selection: $surface) {
                        ForEach(CourtSurface.allCases) { surface in
                            Text(surface.label(locale: locale)).tag(surface)
                        }
                    }
                }

            }
            .navigationTitle(L10n.string("Match Setup", locale: locale))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("Back", locale: locale)) {
                        showingMatchSetup = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func startWarmup() {
        warmupViewModel = MatchViewModel()
    }

    private func startMatch() {
        guard let viewModel = warmupViewModel else { return }
        viewModel.startMatch(
            server: firstServer,
            noAd: noAd,
            gamesPerSet: gamesPerSet,
            setsToWin: setsToWin,
            surface: surface
        )
        showingMatchSetup = false
        activeMatchViewModel = viewModel
    }

    private func resetMatch() {
        activeMatchViewModel = nil
        warmupViewModel = nil
        showingMatchSetup = false
        opponentName = ""
    }

    private var matchIsActive: Binding<Bool> {
        Binding(
            get: { activeMatchViewModel != nil },
            set: { isActive in
                if !isActive {
                    activeMatchViewModel = nil
                }
            }
        )
    }
}
