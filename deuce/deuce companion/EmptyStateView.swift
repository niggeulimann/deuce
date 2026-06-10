import SwiftUI

struct EmptyStateView: View {
    let imageName: String
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 330)
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, 44)
        .padding(.bottom, 12)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
