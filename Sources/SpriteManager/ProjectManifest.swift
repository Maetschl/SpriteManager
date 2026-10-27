import Foundation

struct ProjectManifest: Codable, Sendable {
    static let currentSchemaVersion = 3

    var schemaVersion: Int = Self.currentSchemaVersion
    var project: SpriteProject
    var assets: [SpriteAsset]
}

