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

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .systemDefault
    }

    var body: some View {
        TabView {
            MatchesListView()
                .tabItem { Label("Matches", systemImage: "list.bullet") }
            OpponentsListView()
                .tabItem { Label("Opponents", systemImage: "person.2") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .environment(\.locale, language.locale)
        .tint(.green)
        .preferredColorScheme(theme.colorScheme)
    }
}
