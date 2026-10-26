import Foundation

struct LibraryIndex: Codable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = Self.currentSchemaVersion
    var assets: [SpriteAsset]
}

