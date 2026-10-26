import Testing
@testable import SpriteManager

@Suite("SpriteSheetCodingKeys")
struct SpriteSheetCodingKeysTests {
    @Test func containsRequiredKeys() {
        #expect(SpriteSheetCodingKeys.allCases.count == 7)
    }
}
