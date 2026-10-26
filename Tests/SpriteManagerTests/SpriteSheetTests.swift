import Testing
@testable import SpriteManager

@Suite("SpriteSheet")
struct SpriteSheetTests {
    @Test func clampsInvalidCanvasValues() {
        let sheet = SpriteSheet(name: "Sheet", canvasWidth: 0, canvasHeight: -1, gridSize: 0)
        #expect(sheet.canvasWidth == 1)
        #expect(sheet.canvasHeight == 1)
        #expect(sheet.gridSize == 1)
    }
}

