import Testing
@testable import SpriteManager

@Suite("AppPalette")
struct AppPaletteTests {
    @Test func exposesApplicationColors() {
        #expect(AppPalette.window != AppPalette.canvas)
        #expect(AppPalette.panel != AppPalette.muted)
    }
}
