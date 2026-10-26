import Testing
@testable import SpriteManager

@Suite("SpriteManagerAppDelegate")
@MainActor
struct SpriteManagerAppDelegateTests {
    @Test func canBeConstructed() {
        _ = SpriteManagerAppDelegate()
        #expect(String(describing: SpriteManagerAppDelegate.self) == "SpriteManagerAppDelegate")
    }
}
