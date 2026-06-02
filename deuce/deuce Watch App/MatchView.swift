import SwiftUI
import SwiftData
#if canImport(WatchKit)
import WatchKit
#endif

struct MatchView: View {
    @Binding var isActive: Bool
    var vm: MatchViewModel
    var healthManager: HealthManager
    var healthOptIn: Bool
    @Environment(\.modelContext) private var modelContext

    // Page order: Score (left) · Court (main) · Health (right)
    @State private var selectedPage = Page.court

    private enum Page: Hashable {
        case score, court, health
    }

    var body: some View {
        pageView
            .onAppear  { if healthOptIn { healthManager.startWorkout() } }
            .onDisappear { healthManager.stopWorkout() }
    }

    @ViewBuilder private var pageView: some View {
        let court  = CourtPageView(vm: vm, onExit: saveAndExit, onPoint: handlePoint)
        let score  = ScorePageView(vm: vm, onExit: saveAndExit)
        let health = HealthView(manager: healthManager)
#if os(watchOS)
        TabView(selection: $selectedPage) {
            score .tag(Page.score)
            court .tag(Page.court)
            health.tag(Page.health)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
#else
        TabView(selection: $selectedPage) {
            score .tag(Page.score)
            court .tag(Page.court)
            health.tag(Page.health)
        }
#endif
    }

    private func handlePoint(for side: Side) {
        let result = vm.point(for: side)
#if canImport(WatchKit)
        if result.setWon        { WKInterfaceDevice.current().play(.success) }
        else if result.gameWon  { WKInterfaceDevice.current().play(.success) }
        else                    { WKInterfaceDevice.current().play(.click) }
#endif
    }

    func saveAndExit(isComplete: Bool) {
        healthManager.stopWorkout()
        let record = vm.makeRecord(isComplete: isComplete)
        modelContext.insert(record)
        isActive = false
    }
}

// MARK: - Page 0: Court

private struct CourtPageView: View {
    var vm: MatchViewModel
    let onExit: (Bool) -> Void    // isComplete
    let onPoint: (Side) -> Void

    private let lineColor    = Color(white: 0.92).opacity(0.65)
    private let courtPadH: CGFloat  = 8
    private let courtPadTop: CGFloat = 4

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    courtBlock(geo: geo)
                        .padding(.horizontal, courtPadH)
                        .padding(.top, courtPadTop)

                    // Side-switch overlay
                    if vm.sideSwitch {
                        sideSwitchOverlay
                    }
                    // Match-over overlay
                    if let winner = vm.matchWon {
                        matchOverOverlay(winner: winner)
                    }
                }
            }
            .toolbar { undoToolbarItem }
            .navigationTitle("")
#if os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    // MARK: Court block

    @ViewBuilder
    private func courtBlock(geo: GeometryProxy) -> some View {
        let netH: CGFloat = 12
        let availH = geo.size.height - courtPadTop
        let halfH  = (availH - netH) / 2

        VStack(spacing: 0) {
            halfView(side: .top,    height: halfH)
            NetView().frame(height: netH)
            halfView(side: .bottom, height: halfH)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.3), value: vm.server)
        .animation(.easeInOut(duration: 0.3), value: vm.serveBox)
    }

    @ViewBuilder
    private func halfView(side: Side, height: CGFloat) -> some View {
        let isServer = vm.server == side
        let score    = side == .top ? vm.topScore    : vm.bottomScore
        let games    = side == .top ? vm.topGames    : vm.bottomGames

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
        let myBox: ServeBox = isServer ? box : (box == .left ? .right : .left)

        let alignment: Alignment = {
            let isLeft = myBox == .left
            switch (isLeft, side) {
            case (true,  .top):    return .topLeading
            case (true,  .bottom): return .bottomLeading
            case (false, .top):    return .topTrailing
            default:               return .bottomTrailing
            }
        }()

        GeometryReader { _ in
            ZStack(alignment: alignment) {
                Color.clear
                Group {
                    if isServer {
                        // Server marker: tennis ball (same icon as start screen)
                        Image(systemName: "tennisball.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.4), radius: 2)
                    } else {
                        // Receiver marker: small dot
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 7, height: 7)
                            .shadow(color: .black.opacity(0.4), radius: 2)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
            }
        }
    }

    // MARK: Side-switch overlay

    private var sideSwitchOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, courtPadH)
                .padding(.top, courtPadTop)

            VStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 26, weight: .bold))
                Text("Change Ends")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
        }
        .onTapGesture { vm.dismissSideSwitch() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                vm.dismissSideSwitch()
            }
        }
    }

    @ViewBuilder
    private func matchOverOverlay(winner: Side) -> some View {
        let youWon = winner == .bottom
        ZStack {
            Color.black.opacity(0.7)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, courtPadH)
                .padding(.top, courtPadTop)

            VStack(spacing: 8) {
                Image(systemName: youWon ? "trophy.fill" : "hand.thumbsup")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(youWon ? .yellow : .white)
                Text(youWon ? "You Won!" : "Defeat")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Button {
                    onExit(true)
                } label: {
                    Text("Done")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(youWon ? .yellow : .gray)
            }
            .foregroundStyle(.white)
            .padding(16)
        }
    }

    // MARK: Toolbar

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
}

// MARK: - Page 1: Score + Sets

private struct ScorePageView: View {
    var vm: MatchViewModel
    let onExit: (Bool) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                setTable
                Spacer()
                currentGameScore
                Spacer()
                endButton
            }
        }
    }

    // Set history table + current set column
    private var setTable: some View {
        HStack(spacing: 0) {
            // Row labels
            VStack(alignment: .leading, spacing: 4) {
                Text("")
                    .font(.system(size: 10))
                    .frame(height: 14)
                Text("Opponent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("You")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 46, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Past sets
                    ForEach(Array(vm.setHistory.enumerated()), id: \.offset) { i, set in
                        setColumn(
                            header: String(localized: "Set \(i + 1)"),
                            top: set.top,
                            bottom: set.bottom,
                            highlight: false
                        )
                    }
                    // Current set
                    setColumn(
                        header: String(localized: "Set \(vm.setHistory.count + 1)"),
                        top: vm.topGames,
                        bottom: vm.bottomGames,
                        highlight: true
                    )
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func setColumn(header: String, top: Int, bottom: Int, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Text(header)
                .font(.system(size: 10, weight: highlight ? .semibold : .regular))
                .foregroundStyle(highlight ? .primary : .secondary)
                .frame(height: 14)
            Text("\(top)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? .white : .secondary)
            Text("\(bottom)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? .white : .secondary)
        }
        .frame(width: 32)
    }

    private var currentGameScore: some View {
        HStack(spacing: 10) {
            Text(vm.topScore)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(vm.server == .top ? .yellow : .white)
                .minimumScaleFactor(0.6)
            Text("–")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.secondary)
            Text(vm.bottomScore)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(vm.server == .bottom ? .yellow : .white)
                .minimumScaleFactor(0.6)
        }
    }

    private var endButton: some View {
        Button { onExit(false) } label: {
            Text("End Match")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red.opacity(0.7))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
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
