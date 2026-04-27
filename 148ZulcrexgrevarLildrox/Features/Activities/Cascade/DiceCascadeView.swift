import SwiftUI

struct DiceCascadeView: View {
    let session: GameSession
    let onComplete: (ActivityResultPayload) -> Void

    @EnvironmentObject private var appData: AppData
    @StateObject private var viewModel: DiceCascadeViewModel
    @State private var startDate = Date()
    @State private var reported = false
    @State private var currentDragging: UUID?

    init(session: GameSession, onComplete: @escaping (ActivityResultPayload) -> Void) {
        self.session = session
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: DiceCascadeViewModel(difficulty: session.difficulty, levelIndex: session.levelIndex))
    }

    var body: some View {
        GeometryReader { geo in
            let rawWidth = geo.size.width
            let safeWidth = (rawWidth.isFinite && rawWidth > 0) ? rawWidth : 400
            let usableWidth = max(1, safeWidth - AppDesign.padding * 2)
            let columnStride = max(0.2, usableWidth / 5)
            let rowHeight: CGFloat = 54
            let cellW = max(1, columnStride - 6)
            let cellH = max(1, rowHeight - 6)
            let diceSize = max(8, min(columnStride, rowHeight) - 10)

            ScrollView {
                VStack(alignment: .leading, spacing: AppDesign.padding) {
                    cascadeHeaderPanel

                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 6) {
                            ForEach(0..<viewModel.totalRows, id: \.self) { row in
                                HStack(spacing: 6) {
                                    ForEach(0..<5, id: \.self) { col in
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(
                                                (row + col).isMultiple(of: 2)
                                                    ? Color.appBackground.opacity(0.22)
                                                    : Color.appBackground.opacity(0.12)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .strokeBorder(Color.appAccent.opacity(0.18), lineWidth: 1)
                                            )
                                            .frame(width: cellW, height: cellH)
                                    }
                                }
                            }
                        }
                        .frame(width: usableWidth)

                        ForEach(viewModel.dice) { die in
                            let dieID = die.id
                            DiceFaceShape(value: die.value, size: diceSize)
                                .position(
                                    x: CGFloat(die.column) * columnStride + columnStride / 2,
                                    y: CGFloat(die.row) * rowHeight + rowHeight / 2
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 2)
                                        .onChanged { value in
                                            if currentDragging == nil {
                                                viewModel.beginColumnDrag(dieID: dieID)
                                                currentDragging = dieID
                                            }
                                            guard currentDragging == dieID else { return }
                                            viewModel.updateColumnDrag(
                                                dieID: dieID,
                                                translationWidth: value.translation.width,
                                                gridWidth: usableWidth
                                            )
                                        }
                                        .onEnded { _ in
                                            guard currentDragging == dieID else { return }
                                            viewModel.endColumnDrag(dieID: dieID)
                                            currentDragging = nil
                                        }
                                )
                        }
                    }
                    .frame(width: usableWidth, height: CGFloat(viewModel.totalRows) * rowHeight)
                    .padding(12)
                    .background { AppChrome.depthCard(cornerRadius: 22, rimOpacity: 0.32) }
                    .padding(.bottom, 4)

                    Text("Drag dice sideways to match the run. The lane keeps falling.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .appScreenPadding()
            }
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

    private var cascadeHeaderPanel: some View {
        let overPar = viewModel.elapsed > viewModel.parTime
        let progress = min(1, viewModel.elapsed / max(viewModel.parTime, 1))
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Objective")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(session.difficulty.titleKey)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.appPrimary.opacity(0.85)))
                }
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    ForEach(Array(viewModel.targetSequence.enumerated()), id: \.offset) { _, value in
                        DiceFaceShape(value: value, size: 44)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Pace")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Text("\(Int(viewModel.elapsed))s / \(Int(viewModel.parTime))s par")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(overPar ? Color.appAccent : Color.appTextPrimary)
                }
                GeometryReader { g in
                    let w = max(0, g.size.width * progress)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appSurface.opacity(0.65))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: overPar
                                        ? [Color.appAccent.opacity(0.85), Color.appPrimary.opacity(0.5)]
                                        : [Color.appPrimary, Color.appAccent.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: w)
                            .animation(AppDesign.easeInOut(), value: progress)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(16)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.36) }
    }

    private func handleCompletion(_ phase: DiceCascadeViewModel.Phase) {
        switch phase {
        case .playing:
            return
        case .won, .lost:
            emitOutcome(won: phase == .won)
        }
    }

    private func handleAbandonIfNeeded() {
        guard reported == false else { return }
        emitOutcome(won: false)
    }

    private func emitOutcome(won: Bool) {
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
            totemHeight: nil,
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
