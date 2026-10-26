import Testing
@testable import SpriteManager

@Suite("PlacementPosition")
struct PlacementPositionTests {
    @Test func storesIntegerCoordinates() {
        #expect(PlacementPosition(x: 3, y: 7) == PlacementPosition(x: 3, y: 7))
    }
}

