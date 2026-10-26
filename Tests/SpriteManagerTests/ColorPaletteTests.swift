import Testing
@testable import SpriteManager

@Suite("ColorPalette")
struct ColorPaletteTests {
    @Test func resolvesAliasesThroughTargetOutput() {
        let target = PaletteColor(source: PaletteRGBColor(r: 0, g: 0, b: 255), output: PaletteRGBColor(r: 0, g: 255, b: 0))
        let source = PaletteRGBColor(r: 255, g: 0, b: 0)
        let palette = ColorPalette(colors: [target], aliases: [PaletteAlias(source: source, targetColorID: target.id)])
        #expect(palette.outputColor(for: source) == PaletteRGBColor(r: 0, g: 255, b: 0))
    }
}

