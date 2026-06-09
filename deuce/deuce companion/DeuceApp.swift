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
    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }

    var body: some View {
        TabView {
            MatchesListView()
                .tabItem { Label("Matches", systemImage: "list.bullet") }
            OpponentsListView()
                .tabItem { Label(String(localized: "Opponents"), systemImage: "person.2") }
            StatsView()
                .tabItem { Label(String(localized: "Stats"), systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label(String(localized: "Settings"), systemImage: "gearshape") }
        }
        .tint(.green)
        .preferredColorScheme(theme.colorScheme)
    }
}
