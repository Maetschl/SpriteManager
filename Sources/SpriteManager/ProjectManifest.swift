import Foundation

struct ProjectManifest: Codable, Sendable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int = Self.currentSchemaVersion
    var project: SpriteProject
    var assets: [SpriteAsset]
}

