import Testing
@testable import SpriteManager

@Suite("SpriteManagerApp")
@MainActor
struct SpriteManagerAppTests {
    @Test func canBeConstructed() {
        _ = SpriteManagerApp()
        #expect(String(describing: SpriteManagerApp.self) == "SpriteManagerApp")
    }
}
