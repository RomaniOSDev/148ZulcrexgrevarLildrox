import Foundation

enum DifficultyLevel: String, CaseIterable, Identifiable, Codable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

enum ActivityKind: Int, CaseIterable, Identifiable, Codable {
    case cascade = 0
    case totem = 1
    case path = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .cascade: return "Dice Cascade"
        case .totem: return "Totem Tower"
        case .path: return "Path of Chance"
        }
    }

    var subtitle: String {
        switch self {
        case .cascade: return "Slide dice, match the run before the drop."
        case .totem: return "Rotate and stack before time runs out."
        case .path: return "Roll wisely to reach the far node."
        }
    }
}

struct LevelProgressSnapshot: Codable, Equatable {
    var bestStarsByLevel: [String: [Int]]

    static let empty = LevelProgressSnapshot(bestStarsByLevel: [:])

    func progressKey(activity: ActivityKind, difficulty: DifficultyLevel) -> String {
        "\(activity.rawValue)_\(difficulty.rawValue)"
    }

    func bestStars(activity: ActivityKind, difficulty: DifficultyLevel, levelIndex: Int) -> Int {
        let key = progressKey(activity: activity, difficulty: difficulty)
        guard let arr = bestStarsByLevel[key], levelIndex >= 0, levelIndex < arr.count else { return 0 }
        return arr[levelIndex]
    }

    mutating func setBestStars(activity: ActivityKind, difficulty: DifficultyLevel, levelIndex: Int, stars: Int) {
        let key = progressKey(activity: activity, difficulty: difficulty)
        var arr = bestStarsByLevel[key] ?? Array(repeating: 0, count: GameConstants.levelsPerActivity)
        let cap = GameConstants.levelsPerActivity
        if arr.count < cap {
            arr.append(contentsOf: Array(repeating: 0, count: cap - arr.count))
        } else if arr.count > cap {
            arr = Array(arr.prefix(cap))
        }
        if levelIndex >= 0, levelIndex < cap {
            arr[levelIndex] = max(arr[levelIndex], stars)
        }
        bestStarsByLevel[key] = arr
    }

    /// Pads or trims stored rows when `levelsPerActivity` changes (e.g. after an app update).
    mutating func normalizeArraysToCurrentLevelCount() {
        let cap = GameConstants.levelsPerActivity
        for key in bestStarsByLevel.keys {
            guard var arr = bestStarsByLevel[key] else { continue }
            if arr.count < cap {
                arr.append(contentsOf: Array(repeating: 0, count: cap - arr.count))
            } else if arr.count > cap {
                arr = Array(arr.prefix(cap))
            }
            bestStarsByLevel[key] = arr
        }
    }

    func isUnlocked(activity: ActivityKind, difficulty: DifficultyLevel, levelIndex: Int) -> Bool {
        if levelIndex == 0 { return true }
        return bestStars(activity: activity, difficulty: difficulty, levelIndex: levelIndex - 1) > 0
    }

    func allLevelsCleared(activity: ActivityKind, difficulty: DifficultyLevel) -> Bool {
        (0..<GameConstants.levelsPerActivity).allSatisfy { bestStars(activity: activity, difficulty: difficulty, levelIndex: $0) > 0 }
    }
}

struct GameStatistics: Codable, Equatable {
    var cascadeSessions: Int = 0
    var cascadeWins: Int = 0
    var cascadeBestTime: TimeInterval?
    var totemSessions: Int = 0
    var totemWins: Int = 0
    var totemBestHeight: Int = 0
    var pathSessions: Int = 0
    var pathWins: Int = 0
    var pathBestRolls: Int?
    var totalPlaySeconds: TimeInterval = 0
    var threeStarFinishes: Int = 0
}

enum GameConstants {
    static let levelsPerActivity = 15
}

enum AchievementDefinition: String, CaseIterable, Identifiable {
    case firstWin
    case cascadeMaster
    case totemBuilder
    case pathNavigator
    case harmonyTriple
    case allActivities

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstWin: return "First Victory"
        case .cascadeMaster: return "Cascade Specialist"
        case .totemBuilder: return "Steady Stack"
        case .pathNavigator: return "Pathfinder"
        case .harmonyTriple: return "Triple Shine"
        case .allActivities: return "Full Spectrum"
        }
    }

    var detail: String {
        switch self {
        case .firstWin: return "Win any activity once."
        case .cascadeMaster: return "Earn 3 stars on any Cascade level."
        case .totemBuilder: return "Reach a 6-block tower in Totem Tower."
        case .pathNavigator: return "Finish Path of Chance in 10 rolls or fewer."
        case .harmonyTriple: return "Collect 10 finishes with 3 stars."
        case .allActivities: return "Clear at least one level in each activity."
        }
    }
}
