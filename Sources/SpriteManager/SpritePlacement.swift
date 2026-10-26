import Foundation

struct SpritePlacement: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var spriteID: UUID
    var x: Int
    var y: Int
    var zIndex: Int

    init(id: UUID = UUID(), spriteID: UUID, x: Int = 0, y: Int = 0, zIndex: Int = 0) {
        self.id = id
        self.spriteID = spriteID
        self.x = x
        self.y = y
        self.zIndex = zIndex
    }
}

