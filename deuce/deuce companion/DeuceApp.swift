import SwiftUI
import SwiftData

@main
struct DeuceApp: App {
    private let modelContainer: ModelContainer
    @State private var showsSplash = true

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Schema(versionedSchema: DeuceSchemaV4.self),
                migrationPlan: DeuceMigrationPlan.self
            )
        } catch {
            fatalError("Failed to create iPhone SwiftData container: \(error)")
        }
        PhoneSyncManager.shared.configure(container: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()

                if showsSplash {
                    LaunchSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                guard showsSplash else { return }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeOut(duration: 0.25)) {
                    showsSplash = false
                }
            }
        }
        .modelContainer(modelContainer)
    }
}

struct RootTabView: View {
    @AppStorage("appTheme") private var themeRaw = AppTheme.dark.rawValue
    @AppStorage("accentThemeKey") private var accentKey = AccentTheme.green.rawValue
    @State private var selectedTab = AppTab.play

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }
    private var accent: Color {
        AccentTheme(rawValue: accentKey)?.color ?? .green
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PhonePlayView()
                .tabItem { Label("Play", systemImage: "tennisball.fill") }
                .tag(AppTab.play)
            MatchesListView()
                .tabItem { Label("Matches", systemImage: "list.bullet") }
                .tag(AppTab.matches)
            OpponentsListView()
                .tabItem { Label("Opponents", systemImage: "person.2") }
                .tag(AppTab.opponents)
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(AppTab.stats)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .gesture(tabSwipeGesture, including: .gesture)
        .tint(accent)
        .preferredColorScheme(theme.colorScheme)
    }

    private var tabSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontalDistance = value.predictedEndTranslation.width
                let verticalDistance = value.predictedEndTranslation.height

                guard abs(horizontalDistance) > 80,
                      abs(horizontalDistance) > abs(verticalDistance) * 1.5 else {
                    return
                }

                guard horizontalDistance < 0 || value.startLocation.x > 32 else {
                    return
                }

                withAnimation(.easeOut(duration: 0.2)) {
                    selectedTab = horizontalDistance < 0
                        ? selectedTab.next
                        : selectedTab.previous
                }
            }
    }
}

private enum AppTab: Int, CaseIterable {
    case play
    case matches
    case opponents
    case stats
    case settings

    var previous: AppTab {
        AppTab(rawValue: rawValue - 1) ?? self
    }

    var next: AppTab {
        AppTab(rawValue: rawValue + 1) ?? self
    }
}

private struct LaunchSplashView: View {
    var body: some View {
        Image("LaunchHero")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .background(Color.black)
    }
}
