import SwiftUI
import HealthKit

struct HealthView: View {
    let manager: HealthManager

    var body: some View {
        if !manager.isAuthorized {
            deniedView
        } else {
            metricsView
        }
    }

    // MARK: - Metrics

    private var metricsView: some View {
        VStack(spacing: 0) {
            // Header
            Text("Workout")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Divider().padding(.vertical, 6)

            // 2×3 metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                metricCell(icon: "timer",
                           value: manager.elapsedFormatted,
                           label: String(localized: "Duration"),
                           color: .white)
                metricCell(icon: "heart.fill",
                           value: manager.heartRate > 0 ? "\(Int(manager.heartRate))" : "--",
                           label: "bpm",
                           color: .red)
                metricCell(icon: "shoeprints.fill",
                           value: manager.steps > 0 ? "\(Int(manager.steps))" : "--",
                           label: String(localized: "Steps"),
                           color: .cyan)
                metricCell(icon: "figure.run",
                           value: manager.distanceFormatted,
                           label: String(localized: "Distance"),
                           color: .green)
                metricCell(icon: "flame.fill",
                           value: manager.activeCalories > 0 ? "\(Int(manager.activeCalories))" : "--",
                           label: "kcal",
                           color: .orange)
            }
            .padding(.horizontal, 8)

            Spacer()
        }
    }

    private func metricCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Permission denied

    private var deniedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.slash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Health Access")
                .font(.system(size: 13, weight: .semibold))
            Text(String(localized: "health.access.hint"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
}
