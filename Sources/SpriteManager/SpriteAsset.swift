import Foundation

struct SpriteAsset: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var category: SpriteCategory
    let width: Int
    let height: Int
    var contentHash: String
    var originalFileName: String
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        category: SpriteCategory = .unassigned,
        width: Int,
        height: Int,
        contentHash: String,
        originalFileName: String,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.width = width
        self.height = height
        self.contentHash = contentHash
        self.originalFileName = originalFileName
        self.tags = Self.normalizedTags(tags)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, category, width, height, contentHash, originalFileName, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(SpriteCategory.self, forKey: .category)
        self.width = try container.decode(Int.self, forKey: .width)
        self.height = try container.decode(Int.self, forKey: .height)
        self.contentHash = try container.decode(String.self, forKey: .contentHash)
        self.originalFileName = try container.decode(String.self, forKey: .originalFileName)
        self.tags = Self.normalizedTags(try container.decodeIfPresent([String].self, forKey: .tags) ?? [])
    }

    private static func normalizedTags(_ tags: [String]) -> [String] {
        Array(Set(tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }))
            .sorted()
    }
}

