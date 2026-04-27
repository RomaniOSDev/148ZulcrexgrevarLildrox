import Combine
import Foundation
import SwiftUI

@MainActor
final class TotemTowerViewModel: ObservableObject {
    enum Phase {
        case playing
        case won
        case lost
    }

    struct PlacedDie: Identifiable, Equatable {
        let id: UUID
        var angleDegrees: Double
        let value: Int
        /// Horizontal offset in points when placed (affects balance and look).
        let horizontalShift: CGFloat
    }

    let difficulty: DifficultyLevel
    let levelIndex: Int
    let targetHeight: Int

    @Published private(set) var phase: Phase = .playing
    @Published private(set) var stack: [PlacedDie] = []
    @Published var workingAngle: Double = 0
    @Published private(set) var balance: Double = 100
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var rotationsUsed: Int = 0
    @Published private(set) var workingHorizontal: CGFloat = 0

    private var countdownCancellable: AnyCancellable?
    private var physicsCancellable: AnyCancellable?
    private let maxRotations: Int?
    /// Whether a rotation budget applies (normal / hard).
    var hasRotationLimit: Bool { maxRotations != nil }
    private var horizontalDragActive = false
    private var horizontalDragOrigin: CGFloat = 0

    init(difficulty: DifficultyLevel, levelIndex: Int) {
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        self.targetHeight = min(12, 3 + levelIndex + (difficulty == .hard ? 1 : 0))
        let baseTime: TimeInterval = 48 + Double(levelIndex) * 5
        switch difficulty {
        case .easy:
            timeRemaining = baseTime + 12
            maxRotations = nil
        case .normal:
            timeRemaining = baseTime
            maxRotations = 26 + levelIndex * 2
        case .hard:
            timeRemaining = max(26, baseTime - 10)
            maxRotations = 18 + levelIndex * 2
        }
    }

    func start() {
        guard countdownCancellable == nil else { return }
        countdownCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickCountdown()
            }

        physicsCancellable = Timer.publish(every: 0.12, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickPhysics()
            }
    }

    func stop() {
        countdownCancellable?.cancel()
        countdownCancellable = nil
        physicsCancellable?.cancel()
        physicsCancellable = nil
    }

    func applyRotation(delta: Double) {
        guard phase == .playing else { return }
        workingAngle += delta
    }

    func registerRotationStrokeCompleted() {
        guard phase == .playing else { return }
        rotationsUsed += 1
        if let maxRotations, rotationsUsed > maxRotations {
            phase = .lost
            stop()
        }
    }

    func updateHorizontalDrag(translationWidth: CGFloat, maxAbs: CGFloat) {
        guard phase == .playing else { return }
        let cap = max(20, maxAbs)
        if !horizontalDragActive {
            horizontalDragOrigin = workingHorizontal
            horizontalDragActive = true
        }
        workingHorizontal = min(cap, max(-cap, horizontalDragOrigin + translationWidth))
    }

    func endHorizontalDrag() {
        horizontalDragActive = false
    }

    func placeCurrentPiece(value: Int) {
        guard phase == .playing else { return }
        let clampedAngle = ((workingAngle + 180).truncatingRemainder(dividingBy: 360)) - 180
        let shift = workingHorizontal
        let piece = PlacedDie(
            id: UUID(),
            angleDegrees: clampedAngle,
            value: value,
            horizontalShift: shift
        )
        withAnimation(AppDesign.spring) {
            stack.append(piece)
        }
        workingAngle = 0
        workingHorizontal = 0
        endHorizontalDrag()

        if stack.count >= targetHeight {
            phase = .won
            stop()
        }
    }

    func starsIfWinNow() -> Int {
        guard phase == .won else { return 0 }
        let heightScore = min(1, Double(stack.count) / Double(targetHeight))
        let timeScore = max(0, min(1, timeRemaining / 50))
        let blend = (heightScore * 0.55) + (timeScore * 0.45)
        if blend > 0.72 { return 3 }
        if blend > 0.4 { return 2 }
        return 1
    }

    private func tickCountdown() {
        guard phase == .playing else { return }
        timeRemaining -= 1
        if timeRemaining <= 0 {
            phase = stack.count >= targetHeight ? .won : .lost
            stop()
        }
    }

    private func tickPhysics() {
        guard phase == .playing else { return }
        guard let last = stack.last else { return }
        let deviation = alignmentDeviation(for: last.angleDegrees)
        let shiftSum = stack.reduce(0.0) { $0 + Double(abs($1.horizontalShift)) }
        let shiftPenalty = shiftSum * 0.018
        let stress = 0.35 + deviation * 0.02 + Double(stack.count) * 0.04 + shiftPenalty
        balance -= stress * (difficulty == .hard ? 1.15 : difficulty == .normal ? 1.0 : 0.82)
        if balance <= 0 {
            phase = .lost
            stop()
        }
    }

    private func alignmentDeviation(for angle: Double) -> Double {
        let normalized = abs(angle.truncatingRemainder(dividingBy: 90))
        return min(normalized, 90 - normalized)
    }
}
