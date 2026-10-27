import Foundation

struct SpriteProject: Codable, Hashable, Identifiable, Sendable {
    static let currentSchemaVersion = 3

    var schemaVersion: Int = Self.currentSchemaVersion
    let id: UUID
    var name: String
    var sheets: [SpriteSheet]
    var palette: ColorPalette?
    var collections: [SpriteCollection]
    var previewConfiguration: PackPreviewConfiguration?

    init(
        id: UUID = UUID(),
        name: String = "Untitled Project",
        sheets: [SpriteSheet] = [],
        palette: ColorPalette? = nil,
        collections: [SpriteCollection] = [],
        previewConfiguration: PackPreviewConfiguration? = nil
    ) {
        self.id = id
        self.name = name
        self.sheets = sheets
        self.palette = palette
        self.collections = collections
        self.previewConfiguration = previewConfiguration
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, name, sheets, palette, collections, previewConfiguration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.sheets = try container.decode([SpriteSheet].self, forKey: .sheets)
        self.palette = try container.decodeIfPresent(ColorPalette.self, forKey: .palette)
        self.collections = try container.decodeIfPresent([SpriteCollection].self, forKey: .collections) ?? []
        self.previewConfiguration = try container.decodeIfPresent(PackPreviewConfiguration.self, forKey: .previewConfiguration)
    }
}

struct SpriteCollection: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var assetIDs: [UUID]

    init(id: UUID = UUID(), name: String, assetIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.assetIDs = assetIDs
    }
}

struct PackPreviewConfiguration: Codable, Hashable, Sendable {
    var title: String
    var background: RGBAColor
    var spacing: Int
    var scale: Int
    var showsSheetNames: Bool
    var showsPalette: Bool

    init(
        title: String = "",
        background: RGBAColor = RGBAColor(r: 0.08, g: 0.08, b: 0.1, a: 1),
        spacing: Int = 24,
        scale: Int = 4,
        showsSheetNames: Bool = true,
        showsPalette: Bool = true
    ) {
        self.title = title
        self.background = background
        self.spacing = max(0, spacing)
        self.scale = max(1, scale)
        self.showsSheetNames = showsSheetNames
        self.showsPalette = showsPalette
    }
}

