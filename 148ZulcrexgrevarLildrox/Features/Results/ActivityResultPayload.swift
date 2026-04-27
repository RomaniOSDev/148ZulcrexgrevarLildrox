import Foundation

struct ActivityResultPayload: Identifiable, Equatable {
    let id = UUID()
    let activity: ActivityKind
    let levelIndex: Int
    let difficulty: DifficultyLevel
    let won: Bool
    let stars: Int
    let duration: TimeInterval
    let newAchievements: [AchievementDefinition]

    static func == (lhs: ActivityResultPayload, rhs: ActivityResultPayload) -> Bool {
        lhs.id == rhs.id
    }
}
