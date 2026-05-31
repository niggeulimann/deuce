import SwiftUI

struct SettingsView: View {
    @Binding var noAd: Bool
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Toggle("No-Ad", isOn: $noAd)

            Button("Reset Match", role: .destructive) {
                onReset()
                dismiss()
            }
        }
        .navigationTitle("Settings")
    }
}
