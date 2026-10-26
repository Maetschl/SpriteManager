import Testing
@testable import SpriteManager

@Suite("PixelDragPreview")
struct PixelDragPreviewTests {
    @Test func storesIntegerTranslation() {
        #expect(PixelDragPreview(dx: -2, dy: 3) == PixelDragPreview(dx: -2, dy: 3))
    }
}
