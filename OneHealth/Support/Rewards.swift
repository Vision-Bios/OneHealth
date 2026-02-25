import Foundation

struct Reward: Identifiable {
    let id = UUID()
    let title: String
    let threshold: Int
    let message: String
    let isUnlocked: Bool
}
