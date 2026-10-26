import Foundation
import Testing
@testable import SpriteManager

@Suite("PaletteAlias")
struct PaletteAliasTests {
    @Test func storesSourceAndTarget() {
        let target = UUID()
        let alias = PaletteAlias(source: PaletteRGBColor(r: 1, g: 2, b: 3), targetColorID: target)
        #expect(alias.targetColorID == target)
    }
}

