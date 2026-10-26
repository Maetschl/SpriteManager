import Foundation

struct SpriteAsset: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var category: SpriteCategory
    let width: Int
    let height: Int
    var contentHash: String
    var originalFileName: String

    init(
        id: UUID = UUID(),
        name: String,
        category: SpriteCategory = .unassigned,
        width: Int,
        height: Int,
        contentHash: String,
        originalFileName: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.width = width
        self.height = height
        self.contentHash = contentHash
        self.originalFileName = originalFileName
    }
}

