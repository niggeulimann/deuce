import SwiftUI

struct ScorePadView: View {
    let label: String
    let score: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(score)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}
