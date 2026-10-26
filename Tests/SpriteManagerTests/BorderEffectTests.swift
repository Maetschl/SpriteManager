import Testing
@testable import SpriteManager

@Suite("BorderEffect")
struct BorderEffectTests {
    @Test func defaultsToDisabledOnePixelWhite() {
        let border = BorderEffect()
        #expect(!border.enabled)
        #expect(border.thickness == 1)
        #expect(border.color == RGBAColor(r: 1, g: 1, b: 1, a: 1))
    }
}

