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
        canvasWidth: Int = 256,
        canvasHeight: Int = 256,
        gridSize: Int = 16,
        placements: [SpritePlacement] = [],
        borderEffect: BorderEffect = BorderEffect()
    ) {
        self.id = id
        self.name = name
        self.canvasWidth = max(1, canvasWidth)
        self.canvasHeight = max(1, canvasHeight)
        self.gridSize = max(1, gridSize)
        self.placements = placements
        self.borderEffect = borderEffect
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, canvasWidth, canvasHeight, gridSize, placements, borderEffect
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.canvasWidth = max(1, try container.decode(Int.self, forKey: .canvasWidth))
        self.canvasHeight = max(1, try container.decode(Int.self, forKey: .canvasHeight))
        self.gridSize = max(1, try container.decodeIfPresent(Int.self, forKey: .gridSize) ?? 16)
        self.placements = try container.decode([SpritePlacement].self, forKey: .placements)
        self.borderEffect = try container.decodeIfPresent(BorderEffect.self, forKey: .borderEffect) ?? BorderEffect()
    }
}

