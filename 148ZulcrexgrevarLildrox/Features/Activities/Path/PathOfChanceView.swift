import SwiftUI

struct PathOfChanceView: View {
    let session: GameSession
    let onComplete: (ActivityResultPayload) -> Void

    @EnvironmentObject private var appData: AppData
    @StateObject private var viewModel: PathOfChanceViewModel
    @State private var startDate = Date()
    @State private var reported = false

    init(session: GameSession, onComplete: @escaping (ActivityResultPayload) -> Void) {
        self.session = session
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: PathOfChanceViewModel(difficulty: session.difficulty, levelIndex: session.levelIndex))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesign.padding) {
                pathIntroCard
                mazeCanvas
                rollPanel
                rollsFooter
            }
            .appScreenPadding()
        }
        .appRootBackdrop()
        .navigationTitle("Stage \(session.levelIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startDate = Date()
        }
        .onDisappear {
            handleAbandonIfNeeded()
        }
        .onChange(of: viewModel.phase) { phase in
            handleCompletion(phase)
        }
    }

    private var pathIntroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Path rules")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(session.difficulty.titleKey)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.appPrimary.opacity(0.88)))
            }
            Text("Low rolls can pull you backward. The goal only seals after at least \(viewModel.rollsRequiredBeforeGoalCounts) rolls on the path.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.32) }
    }

    private var mazeCanvas: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.appSurface.opacity(0.55), Color.appBackground.opacity(0.35)],
                            center: .center,
                            startRadius: 20,
                            endRadius: max(size.width, size.height) * 0.75
                        )
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                Path { path in
                    let ids = viewModel.orderedNodeIDs
                    guard let first = ids.first,
                          let start = viewModel.layoutPoints[first] else { return }
                    path.move(to: CGPoint(x: start.x * size.width, y: start.y * size.height))
                    for id in ids.dropFirst() {
                        guard let point = viewModel.layoutPoints[id] else { continue }
                        path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineJoin: .round)
                )
                .shadow(color: Color.appAccent.opacity(0.25), radius: 6, y: 0)

                ForEach(viewModel.orderedNodeIDs, id: \.self) { node in
                    if let point = viewModel.layoutPoints[node] {
                        let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                        let isGoal = node == viewModel.goalNode
                        let isHere = node == viewModel.currentNode
                        let diameter: CGFloat = isGoal ? 30 : (isHere ? 26 : 20)
                        ZStack {
                            if isHere {
                                Circle()
                                    .fill(Color.appAccent.opacity(0.25))
                                    .frame(width: diameter + 18, height: diameter + 18)
                            }
                            Circle()
                                .fill(
                                    isGoal
                                        ? AnyShapeStyle(LinearGradient(colors: [Color.appAccent, Color.appPrimary], startPoint: .top, endPoint: .bottom))
                                        : AnyShapeStyle(Color.appSurface.opacity(isHere ? 0.95 : 0.88))
                                )
                                .frame(width: diameter, height: diameter)
                            Circle()
                                .strokeBorder(
                                    isHere || isGoal
                                        ? AnyShapeStyle(Color.appBackground.opacity(0.35))
                                        : AnyShapeStyle(Color.appAccent.opacity(0.35)),
                                    lineWidth: isHere ? 2 : 1
                                )
                                .frame(width: diameter, height: diameter)
                            if isGoal {
                                Image(systemName: "flag.checkered")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.appBackground)
                            }
                        }
                        .position(center)
                    }
                }

                if let roll = viewModel.lastRoll, let point = viewModel.layoutPoints[viewModel.currentNode] {
                    DiceFaceShape(value: roll, size: 50)
                        .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, y: 4)
                        .position(
                            x: point.x * size.width,
                            y: point.y * size.height - 52
                        )
                }
            }
        }
        .frame(height: 300)
        .shadow(color: Color.appPrimary.opacity(0.12), radius: 20, y: 12)
    }

    private var rollPanel: some View {
        VStack(spacing: 14) {
            Button(action: rollTap) {
                Text("Roll die")
                    .font(.headline.weight(.semibold))
                    .appSingleLineTitle()
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                    .appPrimaryCTA(cornerRadius: 16)
            }
            .buttonStyle(.plain)

            if let roll = viewModel.lastRoll {
                HStack(spacing: 12) {
                    Text("Last roll")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    DiceFaceShape(value: roll, size: 48)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { AppChrome.depthCard(cornerRadius: 16, rimOpacity: 0.26) }
            }
        }
    }

    private var rollsFooter: some View {
        HStack {
            Image(systemName: "dice.fill")
                .foregroundStyle(Color.appAccent.opacity(0.8))
            Text("Rolls \(viewModel.rollsUsed) / \(viewModel.maxRolls)")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
        }
        .padding(12)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.75), Color.appSurface.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(0.12), radius: 10, y: 5)
        }
    }

    private func rollTap() {
        viewModel.roll()
    }

    private func handleCompletion(_ phase: PathOfChanceViewModel.Phase) {
        guard reported == false else { return }
        switch phase {
        case .won, .lost:
            finalize(phase == .won)
        default:
            break
        }
    }

    private func handleAbandonIfNeeded() {
        guard reported == false else { return }
        finalize(false)
    }

    private func finalize(_ won: Bool) {
        guard reported == false else { return }
        reported = true
        let duration = Date().timeIntervalSince(startDate)
        let stars = won ? viewModel.starsIfWinNow() : 0
        let baseline = Set(appData.achievements.map(\.rawValue))
        appData.recordSessionOutcome(
            activity: session.activity,
            difficulty: session.difficulty,
            levelIndex: session.levelIndex,
            stars: stars,
            duration: duration,
            won: won,
            totemHeight: nil,
            pathRolls: won ? viewModel.rollsUsed : viewModel.rollsUsed
        )
        let unlocked = appData.achievements.filter { !baseline.contains($0.rawValue) }
        let payload = ActivityResultPayload(
            activity: session.activity,
            levelIndex: session.levelIndex,
            difficulty: session.difficulty,
            won: won,
            stars: stars,
            duration: duration,
            newAchievements: unlocked
        )
        onComplete(payload)
    }
}
