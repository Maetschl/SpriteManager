import Testing
@testable import SpriteManager

@Suite("SpriteCanvas+Constants")
struct SpriteCanvasConstantsExtensionTests {
    @Test func hasOrderedZoomLimits() {
        #expect(SpriteCanvasConstants.minimumZoom <= SpriteCanvasConstants.maximumZoom)
    }
}
