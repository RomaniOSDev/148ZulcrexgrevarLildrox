import Combine
import Foundation
import SwiftUI

extension Notification.Name {
    static let appDataDidReset = Notification.Name("appDataDidReset")
}

@MainActor
final class AppData: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let selectedDifficulty = "selectedDifficulty"
        static let levelProgress = "levelProgress"
        static let statisticsPayload = "statisticsPayload"
        static let storedAchievementIds = "achievements"
    }

    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var revision: UInt = 0

    init() {
        NotificationCenter.default.publisher(for: .appDataDidReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
        migrateLevelProgressRowLengthsIfNeeded()
        mergeAchievementsFromProgress()
    }

    private func migrateLevelProgressRowLengthsIfNeeded() {
        var progress = levelProgress
        let snapshot = progress
        progress.normalizeArraysToCurrentLevelCount()
        if progress != snapshot {
            levelProgress = progress
        }
    }

    private func bump() {
        revision &+= 1
        objectWillChange.send()
    }

    private func reloadFromDefaults() {
        bump()
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set {
            defaults.set(newValue, forKey: Keys.hasSeenOnboarding)
            bump()
        }
    }

    var selectedDifficulty: DifficultyLevel {
        get {
            let raw = defaults.string(forKey: Keys.selectedDifficulty) ?? DifficultyLevel.normal.rawValue
            return DifficultyLevel(rawValue: raw) ?? .normal
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedDifficulty)
            bump()
        }
    }

    var levelProgress: LevelProgressSnapshot {
        get {
            guard let data = defaults.data(forKey: Keys.levelProgress),
                  let decoded = try? JSONDecoder().decode(LevelProgressSnapshot.self, from: data) else {
                return .empty
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.levelProgress)
            }
            bump()
        }
    }

    var statistics: GameStatistics {
        get {
            guard let data = defaults.data(forKey: Keys.statisticsPayload),
                  let decoded = try? JSONDecoder().decode(GameStatistics.self, from: data) else {
                return GameStatistics()
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.statisticsPayload)
            }
            bump()
        }
    }

    private func loadAchievementSet() -> Set<String> {
        guard let data = defaults.data(forKey: Keys.storedAchievementIds),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(arr)
    }

    private func saveAchievementSet(_ value: Set<String>) {
        let arr = Array(value).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            defaults.set(data, forKey: Keys.storedAchievementIds)
        }
    }

    var achievements: [AchievementDefinition] {
        AchievementDefinition.allCases.filter { loadAchievementSet().contains($0.rawValue) }
    }

    func mergeAchievementsFromProgress() {
        let computed = Set(computeAchievements().map(\.rawValue))
        let merged = loadAchievementSet().union(computed)
        if merged != loadAchievementSet() {
            saveAchievementSet(merged)
            bump()
        }
    }

    private func computeAchievements() -> [AchievementDefinition] {
        var result: [AchievementDefinition] = []
        let stats = statistics
        let progress = levelProgress

        if stats.cascadeWins + stats.totemWins + stats.pathWins > 0 {
            result.append(.firstWin)
        }

        let hasCascadeTriple = DifficultyLevel.allCases.contains { diff in
            (0..<GameConstants.levelsPerActivity).contains { idx in
                progress.bestStars(activity: .cascade, difficulty: diff, levelIndex: idx) >= 3
            }
        }
        if hasCascadeTriple {
            result.append(.cascadeMaster)
        }

        if stats.totemBestHeight >= 6 {
            result.append(.totemBuilder)
        }

        if let best = stats.pathBestRolls, best <= 10 {
            result.append(.pathNavigator)
        }

        if stats.threeStarFinishes >= 10 {
            result.append(.harmonyTriple)
        }

        let clearedCascade = DifficultyLevel.allCases.contains { progress.bestStars(activity: .cascade, difficulty: $0, levelIndex: 0) > 0 }
        let clearedTotem = DifficultyLevel.allCases.contains { progress.bestStars(activity: .totem, difficulty: $0, levelIndex: 0) > 0 }
        let clearedPath = DifficultyLevel.allCases.contains { progress.bestStars(activity: .path, difficulty: $0, levelIndex: 0) > 0 }
        if clearedCascade && clearedTotem && clearedPath {
            result.append(.allActivities)
        }

        return Array(Set(result)).sorted { $0.rawValue < $1.rawValue }
    }

    func recordSessionOutcome(
        activity: ActivityKind,
        difficulty: DifficultyLevel,
        levelIndex: Int,
        stars: Int,
        duration: TimeInterval,
        won: Bool,
        totemHeight: Int?,
        pathRolls: Int?
    ) {
        var stats = statistics
        stats.totalPlaySeconds += duration

        switch activity {
        case .cascade:
            stats.cascadeSessions += 1
            if won {
                stats.cascadeWins += 1
                if let previous = stats.cascadeBestTime {
                    stats.cascadeBestTime = min(previous, duration)
                } else {
                    stats.cascadeBestTime = duration
                }
            }
        case .totem:
            stats.totemSessions += 1
            if won {
                stats.totemWins += 1
            }
            if let h = totemHeight {
                stats.totemBestHeight = max(stats.totemBestHeight, h)
            }
        case .path:
            stats.pathSessions += 1
            if won {
                stats.pathWins += 1
                if let rolls = pathRolls {
                    if let best = stats.pathBestRolls {
                        stats.pathBestRolls = min(best, rolls)
                    } else {
                        stats.pathBestRolls = rolls
                    }
                }
            }
        }

        if won && stars >= 3 {
            stats.threeStarFinishes += 1
        }

        statistics = stats

        if won {
            var progress = levelProgress
            progress.setBestStars(activity: activity, difficulty: difficulty, levelIndex: levelIndex, stars: stars)
            levelProgress = progress
        }

        mergeAchievementsFromProgress()
    }

    static func performResetAll() {
        let defaults = UserDefaults.standard
        [Keys.hasSeenOnboarding, Keys.selectedDifficulty, Keys.levelProgress, Keys.statisticsPayload, Keys.storedAchievementIds].forEach {
            defaults.removeObject(forKey: $0)
        }
        defaults.set(DifficultyLevel.normal.rawValue, forKey: Keys.selectedDifficulty)
        NotificationCenter.default.post(name: .appDataDidReset, object: nil)
    }
}
