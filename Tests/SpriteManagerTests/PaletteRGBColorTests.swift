import Testing
@testable import SpriteManager

@Suite("PaletteRGBColor")
struct PaletteRGBColorTests {
    @Test func parsesAndFormatsHex() throws {
        let color = try #require(PaletteRGBColor(hex: "#12aBcF"))
        #expect(color.hex == "#12ABCF")
    }
}

