import Testing
@testable import SpriteManager

@Suite("BorderEffect+Constants")
struct BorderEffectConstantsTests {
    @Test func definesOnePixelDefault() {
        #expect(BorderEffect.defaultThickness == 1)
        #expect(BorderEffect.currentAlgorithmVersion > 0)
    }
}
