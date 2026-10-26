import Testing
@testable import SpriteManager

@Suite("WindowCloseGuardView")
@MainActor
struct WindowCloseGuardViewTests {
    @Test func canBeConstructed() {
        _ = WindowCloseGuardView()
        #expect(String(describing: WindowCloseGuardView.self).contains("WindowCloseGuardView"))
    }
}
