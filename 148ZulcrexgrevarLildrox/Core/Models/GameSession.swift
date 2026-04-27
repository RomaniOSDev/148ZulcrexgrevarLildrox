import Foundation

struct GameSession: Hashable {
    let activity: ActivityKind
    let levelIndex: Int
    let difficulty: DifficultyLevel
}
