import Testing
@testable import SpriteManager

@Suite("PaletteColor")
struct PaletteColorTests {
    @Test func outputDefaultsToSource() {
        let source = PaletteRGBColor(r: 10, g: 20, b: 30)
        #expect(PaletteColor(source: source).output == source)
    }
}

