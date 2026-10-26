import Testing
@testable import SpriteManager

@Suite("WindowDragAreaView")
@MainActor
struct WindowDragAreaViewTests {
    @Test func canBeConstructed() {
        _ = WindowDragAreaView()
        #expect(String(describing: WindowDragAreaView.self).contains("WindowDragAreaView"))
    }
}
