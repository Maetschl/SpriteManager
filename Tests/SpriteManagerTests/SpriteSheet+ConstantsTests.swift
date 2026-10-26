import Testing
@testable import SpriteManager

@Suite("SpriteSheet+Constants")
struct SpriteSheetConstantsTests {
    @Test func definesCanvasDefaults() {
        #expect(SpriteSheet.defaultCanvasWidth == 256)
        #expect(SpriteSheet.defaultCanvasHeight == 256)
        #expect(SpriteSheet.minimumDimension == 1)
    }
}
