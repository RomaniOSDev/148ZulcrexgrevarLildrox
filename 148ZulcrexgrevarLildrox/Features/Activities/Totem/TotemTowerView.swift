import SwiftUI

struct TotemTowerView: View {
    let session: GameSession
    let onComplete: (ActivityResultPayload) -> Void

    @EnvironmentObject private var appData: AppData
    @StateObject private var viewModel: TotemTowerViewModel
    @State private var startDate = Date()
    @State private var reported = false
    @State private var lastTwist = 0.0

    init(session: GameSession, onComplete: @escaping (ActivityResultPayload) -> Void) {
        self.session = session
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: TotemTowerViewModel(difficulty: session.difficulty, levelIndex: session.levelIndex))
    }

    private var towerSway: Double {
        (100 - viewModel.balance) * 0.14
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesign.padding) {
                statusHeaderCard
                balanceBar
                playArena
                controls
            }
            .appScreenPadding()
        }
        .appRootBackdrop()
        .navigationTitle("Stage \(session.levelIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startDate = Date()
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
            handleAbandonIfNeeded()
        }
        .onChange(of: viewModel.phase) { phase in
            handleCompletion(phase)
        }
    }

    private var statusHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build target")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("\(viewModel.stack.count) / \(viewModel.targetHeight) blocks")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .appSingleLineTitle()
                }
                Spacer()
                Text(session.difficulty.titleKey)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.appAccent.opacity(0.9)))
            }
            HStack(spacing: 14) {
                Label("\(Int(max(viewModel.timeRemaining, 0)))s", systemImage: "timer")
                if viewModel.hasRotationLimit {
                    Label("\(viewModel.rotationsUsed) twists", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.appTextSecondary)
            .labelStyle(.titleAndIcon)
            .symbolRenderingMode(.hierarchical)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.36) }
    }

    private var playArena: some View {
        GeometryReader { geo in
            let w = (geo.size.width.isFinite && geo.size.width > 0) ? geo.size.width : 360
            let maxShift = max(36, w * 0.5 - 48)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.65), Color.appSurface.opacity(0.38)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.12), lineWidth: 1)
                    .padding(14)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 0) {
                        currentPiece(maxHorizontal: maxShift)
                            .padding(.bottom, 8)
                            .zIndex(2)

                        VStack(spacing: 2) {
                            ForEach(Array(viewModel.stack.enumerated().reversed()), id: \.1.id) { fromTop, piece in
                                totemBlock(piece: piece, depth: fromTop)
                            }
                        }
                        .rotationEffect(.degrees(towerSway * (viewModel.stack.count > 0 ? 1 : 0)))
                        .animation(AppDesign.easeInOut(), value: viewModel.balance)
                        .padding(.bottom, 4)

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(0.65), Color.appPrimary.opacity(0.35), Color.appTextSecondary.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 11)
                            .shadow(color: Color.appAccent.opacity(0.35), radius: 6, y: 2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                }
            }
        }
        .frame(minHeight: 300, maxHeight: 420)
        .shadow(color: Color.appPrimary.opacity(0.16), radius: 26, y: 16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }

    private func totemBlock(piece: TotemTowerViewModel.PlacedDie, depth: Int) -> some View {
        let lean = sin(piece.angleDegrees * .pi / 180) * 5.5
        return DiceFaceShape(value: piece.value, size: 56)
            .rotationEffect(.degrees(piece.angleDegrees))
            .offset(x: lean + piece.horizontalShift)
            .shadow(color: Color.appPrimary.opacity(0.15), radius: CGFloat(3 + min(depth, 6)), y: 3)
            .transition(
                .asymmetric(
                    insertion: .offset(y: -44)
                        .combined(with: .scale(scale: 0.72))
                        .combined(with: .opacity),
                    removal: .opacity
                )
            )
    }

    private var balanceBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structural balance")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .appSingleLineTitle()
            GeometryReader { geo in
                let raw = geo.size.width * CGFloat(max(0, min(100, viewModel.balance)) / 100)
                let w = raw.isFinite ? max(0, raw) : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurface.opacity(0.7))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w)
                        .animation(AppDesign.easeInOut(), value: viewModel.balance)
                }
            }
            .frame(height: 14)
        }
        .padding(14)
        .background { AppChrome.depthCard(cornerRadius: 16, rimOpacity: 0.26) }
    }

    private func currentPiece(maxHorizontal: CGFloat) -> some View {
        DiceFaceShape(value: nextValue, size: 64)
            .rotationEffect(.degrees(viewModel.workingAngle))
            .offset(x: viewModel.workingHorizontal, y: -6)
            .shadow(color: Color.appAccent.opacity(0.35), radius: 12, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                    .frame(width: 72, height: 72)
                    .allowsHitTesting(false)
            )
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .local)
                    .onChanged { value in
                        viewModel.updateHorizontalDrag(translationWidth: value.translation.width, maxAbs: maxHorizontal)
                    }
                    .onEnded { _ in
                        viewModel.endHorizontalDrag()
                    }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { angle in
                        let delta = angle.degrees - lastTwist
                        lastTwist = angle.degrees
                        viewModel.applyRotation(delta: delta)
                    }
                    .onEnded { _ in
                        lastTwist = 0
                        viewModel.registerRotationStrokeCompleted()
                    }
            )
            .accessibilityLabel("Rotating piece")
    }

    private var nextValue: Int {
        let seed = abs(Int(viewModel.workingAngle.rounded())) % 6 + 1
        return max(1, min(6, seed))
    }

    private var controls: some View {
        VStack(spacing: AppDesign.padding) {
            Button {
                viewModel.placeCurrentPiece(value: nextValue)
                lastTwist = 0
            } label: {
                Text("Drop block")
                    .font(.headline.weight(.semibold))
                    .appSingleLineTitle()
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                    .appPrimaryCTA(cornerRadius: 16)
            }
            .buttonStyle(.plain)

            Text("Slide to aim the landing, twist to square the face, then drop. Off-center blocks drain balance.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func handleCompletion(_ phase: TotemTowerViewModel.Phase) {
        guard reported == false else { return }
        switch phase {
        case .playing:
            return
        case .won, .lost:
            finalize(phase == .won)
        }
    }

    private func handleAbandonIfNeeded() {
        guard reported == false else { return }
        finalize(false)
    }

    private func finalize(_ won: Bool) {
        guard reported == false else { return }
        reported = true
        viewModel.stop()
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
            totemHeight: viewModel.stack.count,
            pathRolls: nil
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
