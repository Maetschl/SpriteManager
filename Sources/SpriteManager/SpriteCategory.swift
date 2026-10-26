import Foundation

enum SpriteCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case unassigned

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

