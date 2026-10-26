import Testing
@testable import SpriteManager

@Suite("SpritePlacement+Constants")
struct SpritePlacementConstantsTests {
    @Test func definesOriginDefaults() {
        #expect(SpritePlacement.defaultCoordinate == 0)
        #expect(SpritePlacement.defaultZIndex == 0)
    }
}
