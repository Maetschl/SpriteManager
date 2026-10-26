import Testing
@testable import SpriteManager

@Suite("SheetRenderMode")
struct SheetRenderModeTests {
    @Test func exposesAllRenderModes() {
        let modes: [SheetRenderMode] = [.source, .committed, .preview]
        #expect(modes.count == 3)
    }
}

