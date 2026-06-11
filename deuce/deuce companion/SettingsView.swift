import SwiftUI

struct SettingsView: View {
    @Environment(\.locale) private var locale
    @AppStorage("appTheme") private var themeRaw = AppTheme.dark.rawValue
    @AppStorage("accentThemeKey") private var accentKey = AccentTheme.green.rawValue

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

                Section(L10n.string("Appearance", locale: locale)) {
                    Picker(L10n.string("Theme", locale: locale), selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }

                Section(L10n.string("Accent", locale: locale)) {
                    HStack(spacing: 18) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button {
                                accentKey = theme.rawValue
                            } label: {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                accentKey == theme.rawValue
                                                    ? Color.primary
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                            .padding(-4)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(theme.label(locale: locale))
                            .accessibilityAddTraits(
                                accentKey == theme.rawValue ? .isSelected : []
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
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
