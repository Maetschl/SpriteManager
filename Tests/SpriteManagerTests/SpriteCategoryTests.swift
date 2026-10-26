import Testing
@testable import SpriteManager

@Suite("SpriteCategory")
struct SpriteCategoryTests {
    @Test func unassignedHasStableDisplayName() {
        #expect(SpriteCategory.unassigned.id == "unassigned")
        #expect(SpriteCategory.unassigned.displayName == "Unassigned")
    }
}

