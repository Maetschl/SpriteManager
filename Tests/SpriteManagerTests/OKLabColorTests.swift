import Testing
@testable import SpriteManager

@Suite("OKLabColor")
struct OKLabColorTests {
    @Test func mathReturnsAStableLightness() {
        #expect(PaletteColorMath.okLab(PaletteRGBColor(r: 255, g: 255, b: 255)).l > 0.9)
    }
}

