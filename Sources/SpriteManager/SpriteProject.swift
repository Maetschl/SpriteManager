import Foundation

struct SpriteProject: Codable, Hashable, Identifiable, Sendable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int = Self.currentSchemaVersion
    let id: UUID
    var name: String
    var sheets: [SpriteSheet]
    var palette: ColorPalette?

    init(id: UUID = UUID(), name: String = "Untitled Project", sheets: [SpriteSheet] = [], palette: ColorPalette? = nil) {
        self.id = id
        self.name = name
        self.sheets = sheets
        self.palette = palette
    }
}

