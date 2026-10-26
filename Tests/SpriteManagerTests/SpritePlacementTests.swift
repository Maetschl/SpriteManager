import Foundation
import Testing
@testable import SpriteManager

@Suite("SpritePlacement")
struct SpritePlacementTests {
    @Test func generatesIndependentIdentity() {
        let spriteID = UUID()
        let placement = SpritePlacement(spriteID: spriteID)
        #expect(placement.spriteID == spriteID)
        #expect(placement.x == 0)
        #expect(placement.y == 0)
    }
}

