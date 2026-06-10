import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var themeRaw = AppTheme.dark.rawValue
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

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

                Section(L10n.string("Appearance")) {
                    Picker(L10n.string("Theme"), selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }

                Section {
                    Picker("Language", selection: $languageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.label).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Language")
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
