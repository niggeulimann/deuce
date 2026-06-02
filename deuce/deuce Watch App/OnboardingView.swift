import SwiftUI

struct OnboardingView: View {
    let onAllow: () -> Void
    let onSkip:  () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red)
                    .padding(.top, 8)

                Text(String(localized: "onboarding.health.title"))
                    .font(.system(size: 15, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding.health.body"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    onAllow()
                } label: {
                    Text(String(localized: "onboarding.health.allow"))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button {
                    onSkip()
                } label: {
                    Text(String(localized: "onboarding.health.skip"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 12)
        }
    }
}
