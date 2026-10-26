import Foundation

struct SpritePlacement: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var spriteID: UUID
    var x: Int
    var y: Int
    var zIndex: Int

    init(
        id: UUID = UUID(),
        spriteID: UUID,
        x: Int = SpritePlacement.defaultCoordinate,
        y: Int = SpritePlacement.defaultCoordinate,
        zIndex: Int = SpritePlacement.defaultZIndex
    ) {
        self.id = id
        self.spriteID = spriteID
        self.x = x
        self.y = y
        self.zIndex = zIndex
    }
}

