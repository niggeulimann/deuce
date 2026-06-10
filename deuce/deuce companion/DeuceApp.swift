import SwiftUI
import SwiftData

@main
struct DeuceApp: App {
    private let modelContainer: ModelContainer

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
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}

struct RootTabView: View {
    @AppStorage("appTheme") private var themeRaw = AppTheme.dark.rawValue
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue
    @State private var selectedTab = AppTab.matches

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .systemDefault
    }

    var body: some View {
        TabView(selection: $selectedTab) {
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
        .simultaneousGesture(tabSwipeGesture)
        .environment(\.locale, language.locale)
        .tint(.green)
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
