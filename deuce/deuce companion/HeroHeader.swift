import SwiftUI

/// Full-width hero banner shown at the top of each companion tab.
///
/// Pass one or more 4:3 asset names in `imageNames`; one is picked when the view
/// first appears. With an empty array a themed placeholder is drawn.
struct HeroHeader: View {
    let title: LocalizedStringKey
    var subtitle: String? = nil
    /// Asset catalog image names to choose from when the view first appears.
    var imageNames: [String] = []
    /// Controls which part of wide artwork remains visible when it is cropped.
    var imageAlignment: Alignment = .center
    /// SF Symbol faded into the placeholder background.
    var motif: String = "tennisball.fill"
    var tint: Color = .green

    @State private var index = 0
    @State private var didPickStart = false

    var body: some View {
        GeometryReader { proxy in
            let pullDistance = max(
                proxy.frame(in: .scrollView(axis: .vertical)).minY,
                0
            )

            heroContent(pullDistance: pullDistance)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height + pullDistance
                )
                .clipped()
                .offset(y: -pullDistance)
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Vary which image greets the user between visits.
            if !didPickStart, imageNames.count > 1 {
                index = Int.random(in: 0..<imageNames.count)
                didPickStart = true
            }
        }
    }

    private func heroContent(pullDistance: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            background(pullDistance: pullDistance)

            // Scrim so the title stays legible on any artwork.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.35),
                    .init(color: .black.opacity(0.62), location: 0.76),
                    .init(color: .black.opacity(0.48), location: 0.86),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                stops: [
                    .init(color: Color(.systemBackground).opacity(0), location: 0),
                    .init(color: Color(.systemBackground).opacity(0), location: 0.45),
                    .init(color: Color(.systemBackground).opacity(0.9), location: 0.86),
                    .init(color: Color(.systemBackground), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 52)
            .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 2) {
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder private func background(pullDistance: CGFloat) -> some View {
        if imageNames.isEmpty {
            placeholder
        } else {
            GeometryReader { proxy in
                ZStack {
                    ForEach(Array(imageNames.enumerated()), id: \.offset) { i, name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height,
                                alignment: imageAlignment
                            )
                            .scaleEffect(
                                1 + pullDistance / (max(proxy.size.height, 1) * 2),
                                anchor: .top
                            )
                            .clipped()
                            .opacity(i == index ? 1 : 0)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.10), tint.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: motif)
                .font(.system(size: 150))
                .foregroundStyle(.white.opacity(0.06))
                .rotationEffect(.degrees(-12))
                .offset(x: 70, y: -8)
        }
    }
}

extension View {
    /// Makes a view a full-bleed, separator-less, transparent list row –
    /// used to drop the hero in as the first row of a List.
    func heroListRow() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
