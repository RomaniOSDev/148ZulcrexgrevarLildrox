import Combine
import Foundation

struct CascadeDie: Identifiable, Equatable {
    let id: UUID
    var column: Int
    var row: Double
    var value: Int
}

@MainActor
final class DiceCascadeViewModel: ObservableObject {
    enum Phase {
        case playing
        case won
        case lost
    }

    let difficulty: DifficultyLevel
    let levelIndex: Int

    @Published private(set) var phase: Phase = .playing
    @Published private(set) var dice: [CascadeDie]
    @Published private(set) var targetSequence: [Int]
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var parTime: TimeInterval

    private var timerCancellable: AnyCancellable?
    private let columns = 5
    private let tickSeconds: TimeInterval
    var totalRows: Int { 9 + levelIndex * 2 }
    private var columnDragStart: [UUID: Int] = [:]
    /// For targets like 3,3,3 a value shuffle cannot be wrong, so a row gate prevents an instant match.
    private var minimumRowForWin: Double = 0

    init(difficulty: DifficultyLevel, levelIndex: Int) {
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        let basePar: TimeInterval = 32 + Double(levelIndex) * 4
        switch difficulty {
        case .easy:
            parTime = basePar + 10
            tickSeconds = 0.78
        case .normal:
            parTime = basePar
            tickSeconds = 0.62
        case .hard:
            parTime = max(18, basePar - 8)
            tickSeconds = 0.48
        }
        let template = DiceCascadeViewModel.makeTarget(for: levelIndex)
        self.targetSequence = template
        self.dice = [
            CascadeDie(id: UUID(), column: 1, row: 0, value: 0),
            CascadeDie(id: UUID(), column: 2, row: 0, value: 0),
            CascadeDie(id: UUID(), column: 3, row: 0, value: 0)
        ]
        assignScrambledValuesAndRowGate()
    }

    func start() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: tickSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func beginColumnDrag(dieID: UUID) {
        guard let die = dice.first(where: { $0.id == dieID }) else { return }
        columnDragStart[dieID] = die.column
    }

    func updateColumnDrag(dieID: UUID, translationWidth: CGFloat, gridWidth: CGFloat) {
        guard phase == .playing else { return }
        guard let index = dice.firstIndex(where: { $0.id == dieID }),
              let start = columnDragStart[dieID] else { return }
        let columnWidth = max(gridWidth / CGFloat(columns), 1)
        let deltaColumns = Int((translationWidth / columnWidth).rounded())
        let newColumn = min(max(start + deltaColumns, 0), columns - 1)
        dice[index].column = newColumn
    }

    func endColumnDrag(dieID: UUID) {
        columnDragStart[dieID] = nil
        guard let index = dice.firstIndex(where: { $0.id == dieID }) else { return }
        dice[index].column = min(max(dice[index].column, 0), columns - 1)
    }

    func starsIfWinNow() -> Int {
        guard phase == .won else { return 0 }
        let ratio = max(0, min(1, 1 - (elapsed / parTime)))
        if ratio > 0.66 { return 3 }
        if ratio > 0.33 { return 2 }
        return 1
    }

    private func tick() {
        guard phase == .playing else { return }
        elapsed += tickSeconds

        for index in dice.indices {
            dice[index].row += 0.22 + Double(levelIndex) * 0.015
        }

        if evaluateWin() {
            phase = .won
            stop()
            return
        }

        let limit = Double(totalRows - 1)
        if dice.contains(where: { $0.row >= limit }) {
            phase = .lost
            stop()
        }
    }

    private func evaluateWin() -> Bool {
        let ordered = dice.sorted { $0.column < $1.column }
        guard ordered.count == 3 else { return false }
        // Same visual band (cascade step keeps all rows aligned when started together).
        let maxRow = ordered.map(\.row).max() ?? 0
        let minRow = ordered.map(\.row).min() ?? 0
        guard maxRow - minRow < 0.12 else { return false }
        guard maxRow >= minimumRowForWin else { return false }
        let values = ordered.map(\.value)
        return values == targetSequence
    }

    private static func makeTarget(for level: Int) -> [Int] {
        let bases: [[Int]] = [
            [2, 3, 5],
            [1, 4, 6],
            [2, 2, 5],
            [3, 3, 3],
            [1, 2, 6],
            [4, 4, 2],
            [1, 3, 5],
            [6, 5, 4],
            [2, 4, 6],
            [1, 1, 6],
            [3, 4, 5],
            [2, 6, 3],
            [4, 1, 5],
            [3, 6, 2],
            [5, 5, 2]
        ]
        return bases[level % bases.count]
    }

    private func assignScrambledValuesAndRowGate() {
        if Set(targetSequence).count == 1 {
            for index in dice.indices {
                dice[index].value = targetSequence[0]
            }
            minimumRowForWin = 1.4
            return
        }

        var permuted: [Int] = targetSequence
        for _ in 0..<100 {
            let candidate = targetSequence.shuffled()
            if candidate != targetSequence {
                permuted = candidate
                break
            }
        }
        if permuted == targetSequence, targetSequence.count == 3 {
            permuted = [targetSequence[0], targetSequence[2], targetSequence[1]]
        }
        if permuted == targetSequence, targetSequence.count == 3 {
            permuted = [targetSequence[1], targetSequence[0], targetSequence[2]]
        }
        for index in 0..<3 {
            dice[index].value = permuted[index]
        }
        minimumRowForWin = 0
    }
}
