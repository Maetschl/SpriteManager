import Testing
@testable import SpriteManager

@Suite("WelcomeWindowController")
@MainActor
struct WelcomeWindowControllerTests {
    @Test func usesSharedController() {
        #expect(WelcomeWindowController.shared === WelcomeWindowController.shared)
    }
}
