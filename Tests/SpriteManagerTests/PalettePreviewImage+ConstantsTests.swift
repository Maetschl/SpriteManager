import Testing
@testable import SpriteManager

@Suite("PalettePreviewImage+Constants")
struct PalettePreviewImageConstantsExtensionTests {
    @Test func hasPositivePreviewHeight() {
        #expect(PalettePreviewImageConstants.previewHeight > 0)
    }
}
