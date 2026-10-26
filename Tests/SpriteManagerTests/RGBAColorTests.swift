import Testing
@testable import SpriteManager

@Suite("RGBAColor")
struct RGBAColorTests {
    @Test func preservesChannels() {
        #expect(RGBAColor(r: 0.2, g: 0.4, b: 0.6, a: 0.8).a == 0.8)
    }
}

