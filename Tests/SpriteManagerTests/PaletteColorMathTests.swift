import Testing
@testable import SpriteManager

@Suite("PaletteColorMath")
struct PaletteColorMathTests {
    @Test func identicalColorsHaveZeroDistance() {
        let color = PaletteRGBColor(r: 10, g: 20, b: 30)
        #expect(PaletteColorMath.distance(color, color) == 0)
    }
}

