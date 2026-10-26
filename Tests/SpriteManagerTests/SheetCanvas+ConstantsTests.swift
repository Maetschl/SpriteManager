import Testing
@testable import SpriteManager

@Suite("SheetCanvas+Constants")
struct SheetCanvasConstantsExtensionTests {
    @Test func hasOrderedZoomLimits() {
        #expect(SheetCanvasConstants.minimumZoom <= SheetCanvasConstants.maximumZoom)
    }
}
