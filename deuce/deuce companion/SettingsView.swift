import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var themeRaw = AppTheme.dark.rawValue

    var body: some View {
        NavigationStack {
            List {
                HeroHeader(
                    title: "Settings",
                    imageNames: ["Settings"],
                    motif: "gearshape.fill",
                    tint: .gray
                )
                    .heroListRow()

                Section(String(localized: "Appearance")) {
                    Picker(String(localized: "Theme"), selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
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
