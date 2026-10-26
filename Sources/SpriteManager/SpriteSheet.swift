import Foundation

struct SpriteSheet: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var canvasWidth: Int
    var canvasHeight: Int
    var gridSize: Int
    var placements: [SpritePlacement]
    var borderEffect: BorderEffect

    init(
        id: UUID = UUID(),
        name: String,
        canvasWidth: Int = SpriteSheet.defaultCanvasWidth,
        canvasHeight: Int = SpriteSheet.defaultCanvasHeight,
        gridSize: Int = SpriteSheet.defaultGridSize,
        placements: [SpritePlacement] = [],
        borderEffect: BorderEffect = BorderEffect()
    ) {
        self.id = id
        self.name = name
        self.canvasWidth = max(SpriteSheet.minimumDimension, canvasWidth)
        self.canvasHeight = max(SpriteSheet.minimumDimension, canvasHeight)
        self.gridSize = max(SpriteSheet.minimumDimension, gridSize)
        self.placements = placements
        self.borderEffect = borderEffect
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SpriteSheetCodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.canvasWidth = max(SpriteSheet.minimumDimension, try container.decode(Int.self, forKey: .canvasWidth))
        self.canvasHeight = max(SpriteSheet.minimumDimension, try container.decode(Int.self, forKey: .canvasHeight))
        self.gridSize = max(
            SpriteSheet.minimumDimension,
            try container.decodeIfPresent(Int.self, forKey: .gridSize) ?? SpriteSheet.defaultGridSize
        )
        self.placements = try container.decode([SpritePlacement].self, forKey: .placements)
        self.borderEffect = try container.decodeIfPresent(BorderEffect.self, forKey: .borderEffect) ?? BorderEffect()
    }
}

