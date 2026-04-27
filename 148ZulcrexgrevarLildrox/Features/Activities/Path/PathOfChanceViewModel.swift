import Combine
import CoreGraphics
import Foundation

struct PathBranch: Equatable {
    let threshold: Int
    let highNode: Int
    let lowNode: Int
}

struct PathMazeDefinition: Equatable {
    let start: Int
    let goal: Int
    let branches: [Int: PathBranch]
    let layout: [Int: CGPoint]

    /// Fewest rolls if every roll picks the branch that moves you closer along the graph (high and low edges each cost one roll).
    static func shortestPathRolls(maze: PathMazeDefinition) -> Int {
        if maze.start == maze.goal { return 0 }
        var queue: [Int] = [maze.start]
        var depth: [Int: Int] = [maze.start: 0]
        var head = 0
        while head < queue.count {
            let u = queue[head]
            head += 1
            guard let b = maze.branches[u] else { continue }
            for v in [b.highNode, b.lowNode] {
                let nextDepth = (depth[u] ?? 0) + 1
                if v == maze.goal {
                    return nextDepth
                }
                if depth[v] == nil {
                    depth[v] = nextDepth
                    queue.append(v)
                }
            }
        }
        return 99
    }

    static func definition(level: Int) -> PathMazeDefinition {
        switch level % 10 {
        case 0:
            return longSpine(goal: 6, lowKick: 0, thresholdPattern: [4, 4, 4, 4, 4, 4])
        case 1:
            return longSpine(goal: 6, lowKick: 0, thresholdPattern: [5, 3, 5, 4, 3, 4])
        case 2:
            return longSpine(goal: 6, lowKick: 1, thresholdPattern: [4, 5, 4, 5, 4, 3])
        case 3:
            return longSpine(goal: 6, lowKick: 0, thresholdPattern: [3, 5, 4, 4, 5, 4])
        case 4:
            return longSpine(goal: 6, lowKick: 2, thresholdPattern: [5, 4, 3, 5, 4, 4])
        case 5:
            return longSpine(goal: 6, lowKick: 1, thresholdPattern: [3, 4, 5, 3, 5, 4])
        case 6:
            return longSpine(goal: 6, lowKick: 0, thresholdPattern: [5, 5, 3, 4, 4, 5])
        case 7:
            return longSpine(goal: 6, lowKick: 2, thresholdPattern: [4, 3, 5, 5, 3, 4])
        case 8:
            return longSpine(goal: 6, lowKick: 0, thresholdPattern: [5, 4, 4, 3, 5, 3])
        default:
            return longSpine(goal: 6, lowKick: 1, thresholdPattern: [4, 4, 5, 3, 4, 5])
        }
    }

    /// Linear spine 0→1→…→goal; low roll kicks back to `lowKick` or previous rung so one lucky streak cannot end in one roll.
    private static func longSpine(goal: Int, lowKick: Int, thresholdPattern: [Int]) -> PathMazeDefinition {
        var branches: [Int: PathBranch] = [:]
        let lastIndex = goal - 1
        for u in 0...lastIndex {
            let thr = thresholdPattern[min(u, thresholdPattern.count - 1)]
            let high = u + 1
            let low: Int
            if u == 0 {
                low = 0
            } else if u <= 2 {
                low = lowKick
            } else {
                low = u - 2
            }
            branches[u] = PathBranch(threshold: thr, highNode: high, lowNode: low)
        }

        let layout: [Int: CGPoint] = [
            0: CGPoint(x: 0.08, y: 0.86),
            1: CGPoint(x: 0.22, y: 0.74),
            2: CGPoint(x: 0.36, y: 0.62),
            3: CGPoint(x: 0.5, y: 0.5),
            4: CGPoint(x: 0.64, y: 0.38),
            5: CGPoint(x: 0.78, y: 0.26),
            6: CGPoint(x: 0.9, y: 0.12)
        ]
        return PathMazeDefinition(start: 0, goal: goal, branches: branches, layout: layout)
    }
}

@MainActor
final class PathOfChanceViewModel: ObservableObject {
    enum Phase {
        case idle
        case rolling
        case moving
        case won
        case lost
    }

    let difficulty: DifficultyLevel
    let levelIndex: Int
    private let maze: PathMazeDefinition
    private let parRolls: Int
    private let minRollsToWin: Int

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var currentNode: Int
    @Published private(set) var lastRoll: Int?
    @Published private(set) var rollsUsed: Int = 0
    @Published private(set) var maxRolls: Int

    var orderedNodeIDs: [Int] {
        Array(maze.layout.keys).sorted()
    }

    var layoutPoints: [Int: CGPoint] {
        maze.layout
    }

    var goalNode: Int {
        maze.goal
    }

    var rollsRequiredBeforeGoalCounts: Int {
        minRollsToWin
    }

    init(difficulty: DifficultyLevel, levelIndex: Int) {
        self.difficulty = difficulty
        self.levelIndex = levelIndex
        self.maze = PathMazeDefinition.definition(level: levelIndex)
        self.currentNode = maze.start
        let baseShortest = PathMazeDefinition.shortestPathRolls(maze: maze)
        let padded = max(4, baseShortest + levelIndex / 2 + (difficulty == .hard ? 1 : 0))
        self.minRollsToWin = min(padded, 12)
        self.parRolls = minRollsToWin + 3 + levelIndex
        switch difficulty {
        case .easy:
            maxRolls = parRolls + 8
        case .normal:
            maxRolls = parRolls + 5
        case .hard:
            maxRolls = max(parRolls + 2, minRollsToWin + 4)
        }
    }

    func roll() {
        guard phase == .idle || phase == .moving else { return }
        if rollsUsed >= maxRolls {
            phase = .lost
            return
        }
        phase = .rolling
        lastRoll = Int.random(in: 1...6)
        rollsUsed += 1
        applyRoll()
    }

    func starsIfWinNow() -> Int {
        guard phase == .won else { return 0 }
        let spare = maxRolls - rollsUsed
        let ratio = Double(spare) / Double(maxRolls)
        if ratio > 0.55 { return 3 }
        if ratio > 0.25 { return 2 }
        return 1
    }

    private func applyRoll() {
        guard let roll = lastRoll else {
            phase = .idle
            return
        }

        if currentNode == maze.goal, rollsUsed >= minRollsToWin {
            phase = .won
            return
        }

        guard let branch = maze.branches[currentNode] else {
            phase = .lost
            return
        }

        let high = branch.highNode
        let low = branch.lowNode
        let primary = roll >= branch.threshold ? high : low
        var next = primary

        if next == maze.goal, rollsUsed < minRollsToWin {
            next = primary == high ? low : high
        }

        currentNode = next
        phase = .moving

        if currentNode == maze.goal, rollsUsed >= minRollsToWin {
            phase = .won
            return
        }
        if rollsUsed >= maxRolls, currentNode != maze.goal {
            phase = .lost
            return
        }
        phase = .idle
    }
}
