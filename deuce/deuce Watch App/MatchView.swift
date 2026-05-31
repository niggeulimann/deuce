import SwiftUI
#if canImport(WatchKit)
import WatchKit
#endif

struct MatchView: View {
    @Binding var isActive: Bool
    var vm: MatchViewModel

    var body: some View {
        pageView
    }

    @ViewBuilder private var pageView: some View {
        let court = CourtPageView(vm: vm, onPoint: handlePoint)
        let score = ScorePageView(vm: vm, isActive: $isActive)
#if os(watchOS)
        TabView {
            court
            score
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
#else
        TabView { court; score }
#endif
    }

    private func handlePoint(for side: Side) {
        let won = vm.point(for: side)
#if canImport(WatchKit)
        WKInterfaceDevice.current().play(won ? .success : .click)
#endif
    }
}

// MARK: - Page 0: Court

private struct CourtPageView: View {
    var vm: MatchViewModel
    let onPoint: (Side) -> Void

    private let lineColor  = Color(white: 0.92).opacity(0.65)
    private let courtPadH: CGFloat = 8
    private let courtPadTop: CGFloat = 4

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                courtBlock(geo: geo)
                    .padding(.horizontal, courtPadH)
                    .padding(.top, courtPadTop)
                    // no bottom padding – court fills to edge
            }
            .toolbar { undoToolbarItem }
            .navigationTitle("")
#if os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    @ToolbarContentBuilder
    private var undoToolbarItem: some ToolbarContent {
#if os(watchOS)
        ToolbarItem(placement: .topBarLeading) { undoButton }
#else
        ToolbarItem(placement: .automatic)    { undoButton }
#endif
    }

    private var undoButton: some View {
        Button { vm.undo() } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 13, weight: .bold))
        }
        .disabled(!vm.canUndo)
        .foregroundStyle(vm.canUndo ? .primary : .tertiary)
    }

    @ViewBuilder
    private func courtBlock(geo: GeometryProxy) -> some View {
        let netH: CGFloat   = 12
        // subtract toolbar + top padding; leave zero at bottom
        let availH = geo.size.height - courtPadTop
        let halfH  = (availH - netH) / 2

        VStack(spacing: 0) {
            halfView(side: .top,    height: halfH)
            NetView().frame(height: netH)
            halfView(side: .bottom, height: halfH)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // Single animation drives both dots together
        .animation(.easeInOut(duration: 0.3), value: vm.server)
        .animation(.easeInOut(duration: 0.3), value: vm.serveBox)
    }

    @ViewBuilder
    private func halfView(side: Side, height: CGFloat) -> some View {
        let isServer = vm.server == side
        let score    = side == .top ? vm.topScore : vm.bottomScore
        let games    = side == .top ? vm.topGames : vm.bottomGames

        Button { onPoint(side) } label: {
            ZStack {
                side == .top ? vm.surface.colorTop : vm.surface.colorBottom

                Rectangle().fill(lineColor).frame(width: 1)

                VStack(spacing: 0) {
                    if side == .top  { Spacer() }
                    Rectangle().fill(lineColor).frame(height: 1)
                    if side == .bottom { Spacer() }
                }

                scoreBadge(score: score, games: games, side: side)
                dotsLayer(side: side, isServer: isServer)
            }
        }
        .buttonStyle(.plain)
        .frame(height: height)
    }

    private func scoreBadge(score: String, games: Int, side: Side) -> some View {
        VStack(spacing: 0) {
            if side == .top  { Spacer() }
            HStack(spacing: 5) {
                Text("\(games)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(vm.surface.accentColor.opacity(0.65))
                Text(score)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(vm.surface.accentColor)
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
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private func dotsLayer(side: Side, isServer: Bool) -> some View {
        let box = vm.serveBox
        let receiverBox: ServeBox = box == .left ? .right : .left
        let myBox = isServer ? box : receiverBox
        let nearBaseline = true   // both server and receiver stand at their own baseline

        let alignment: Alignment = {
            let isLeft = myBox == .left
            switch (isLeft, nearBaseline) {
            case (true,  true):  return side == .top ? .topLeading     : .bottomLeading
            case (true,  false): return side == .top ? .bottomLeading  : .topLeading
            case (false, true):  return side == .top ? .topTrailing    : .bottomTrailing
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
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
            }
        }
    }
}

// MARK: - Page 1: Score details

private struct ScorePageView: View {
    var vm: MatchViewModel
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

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

                Button { isActive = false } label: {
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
