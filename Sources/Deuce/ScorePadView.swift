import SwiftUI

struct ScorePadView: View {
    let label: String
    let score: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(score)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}
