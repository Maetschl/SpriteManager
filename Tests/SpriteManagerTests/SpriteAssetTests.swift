import Testing
@testable import SpriteManager

@Suite("SpriteAsset")
struct SpriteAssetTests {
    @Test func defaultsToUnassigned() {
        let asset = SpriteAsset(name: "Hero", width: 8, height: 8, contentHash: "hash", originalFileName: "hero.png")
        #expect(asset.category == .unassigned)
        #expect(asset.width == 8)
        #expect(asset.height == 8)
    }
}

