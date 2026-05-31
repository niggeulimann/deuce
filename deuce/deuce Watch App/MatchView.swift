import SwiftUI
#if canImport(WatchKit)
import WatchKit
#endif

struct MatchView: View {
    @Binding var isActive: Bool
    var vm: MatchViewModel

    @State private var gameWonSide: Side? = nil

    var body: some View {
        TabView {
            // Page 0 (default): Court
            CourtPageView(vm: vm, gameWonSide: $gameWonSide, isActive: $isActive, onPoint: handlePoint)
            // Page 1 (swipe left): Score details
            ScorePageView(vm: vm, isActive: $isActive)
        }
#if os(watchOS)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: gameWonSide)
    }

    private func handlePoint(for side: Side) {
        let won = vm.point(for: side)
#if canImport(WatchKit)
        WKInterfaceDevice.current().play(won ? .success : .click)
#endif
        if won {
            gameWonSide = side
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                gameWonSide = nil
            }
        }
    }
}

// MARK: - Page 0: Court (main view)

private struct CourtPageView: View {
    var vm: MatchViewModel
    @Binding var gameWonSide: Side?
    @Binding var isActive: Bool
    let onPoint: (Side) -> Void

    private let lineColor = Color(white: 0.92).opacity(0.65)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    halfView(side: .top, geo: geo)
                    NetView()
                        .frame(height: 12)
                    halfView(side: .bottom, geo: geo)
                }

                // Undo – top left overlay
                VStack {
                    HStack {
                        Button {
                            vm.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(vm.canUndo ? .white : .white.opacity(0.2))
                                .padding(8)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!vm.canUndo)
                        .padding(.leading, 6)
                        .padding(.top, 6)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func halfView(side: Side, geo: GeometryProxy) -> some View {
        let halfH = (geo.size.height - 12) / 2
        let isServer = vm.server == side
        let score    = side == .top ? vm.topScore    : vm.bottomScore
        let games    = side == .top ? vm.topGames    : vm.bottomGames
        let won      = gameWonSide == side
        let surface  = vm.surface

        Button { onPoint(side) } label: {
            ZStack {
                // Court surface
                (won ? Color.green.opacity(0.5) : (side == .top ? surface.colorTop : surface.colorBottom))

                // Vertical centre service line
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 1)

                // Horizontal service box line
                VStack(spacing: 0) {
                    if side == .top { Spacer() }
                    Rectangle().fill(lineColor).frame(height: 1)
                    if side == .bottom { Spacer() }
                }

                // Score badge (inverted: white bg, court-color text)
                scoreBadge(score: score, games: games, side: side, isServer: isServer, surface: surface)

                // Server / receiver dots at baseline corners
                dotsLayer(side: side, isServer: isServer)
            }
        }
        .buttonStyle(.plain)
        .frame(height: halfH)
    }

    // Inverted score badge: white pill with court-accent text
    private func scoreBadge(score: String, games: Int, side: Side, isServer: Bool, surface: CourtSurface) -> some View {
        VStack(spacing: 0) {
            if side == .top { Spacer() }
            HStack(spacing: 6) {
                // Games won
                Text("\(games)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(surface.accentColor.opacity(0.7))
                // Current score
                Text(score)
                    .font(.system(size: isServer ? 36 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(surface.accentColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            if side == .bottom { Spacer() }
        }
        .padding(.vertical, 6)
    }

    // Server dot: baseline corner of the correct service box (near sideline/centerline)
    // Receiver dot: diagonally opposite (other half, mirrored box, near net)
    @ViewBuilder
    private func dotsLayer(side: Side, isServer: Bool) -> some View {
        let box = vm.serveBox                                    // screen-relative box of the server
        let receiverBox: ServeBox = box == .left ? .right : .left

        // Which box does this side's dot live in?
        let myBox: ServeBox = isServer ? box : receiverBox

        // Server sits at the baseline (outer edge), receiver at the net (inner edge)
        let atBaseline = isServer

        let alignment: Alignment = {
            let leadingBox = myBox == .left
            switch (leadingBox, atBaseline) {
            case (true,  true):  return side == .top ? .topLeading    : .bottomLeading
            case (true,  false): return side == .top ? .bottomLeading : .topLeading
            case (false, true):  return side == .top ? .topTrailing   : .bottomTrailing
            case (false, false): return side == .top ? .bottomTrailing : .topTrailing
            }
        }()

        GeometryReader { _ in
            ZStack(alignment: alignment) {
                Color.clear
                Circle()
                    .fill(isServer ? Color.yellow : Color.white.opacity(0.6))
                    .frame(width: isServer ? 12 : 7, height: isServer ? 12 : 7)
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    // Tight to the corner – near the court lines
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Page 1: Score details

private struct ScorePageView: View {
    var vm: MatchViewModel
    @Binding var isActive: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Games
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Gegner")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(vm.topGames)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Text(":")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.secondary)
                        .padding(.top, 14)
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Du")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(vm.bottomGames)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    Spacer()
                }

                // Current game score
                HStack(spacing: 12) {
                    Text(vm.topScore)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(vm.server == .top ? .yellow : .white)
                        .minimumScaleFactor(0.6)
                    Text("–")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.secondary)
                    Text(vm.bottomScore)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(vm.server == .bottom ? .yellow : .white)
                        .minimumScaleFactor(0.6)
                }
                .padding(.top, 4)

                Spacer()

                Button {
                    isActive = false
                } label: {
                    Text("Beenden")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Net

private struct NetView: View {
    var body: some View {
        ZStack {
            Color(white: 0.50)
            HStack {
                Capsule().fill(Color(white: 0.75)).frame(width: 4)
                Spacer()
                Capsule().fill(Color(white: 0.75)).frame(width: 4)
            }
            Capsule().fill(Color(white: 0.82)).frame(width: 3)
            VStack(spacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    Rectangle().fill(Color(white: 0.70).opacity(0.55)).frame(height: 1)
                }
            }
            .padding(.horizontal, 6)
        }
    }
}
