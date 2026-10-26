import CoreGraphics
import Testing
@testable import SpriteManager

@Suite("WelcomeLayoutMetrics")
struct WelcomeLayoutMetricsTests {
    @Test func keepsSquareLeftPanelAndThreeFifthsRightPanel() {
        let size = WelcomeLayoutMetrics.windowSize(for: CGSize(width: 2000, height: 1400))
        let panels = WelcomeLayoutMetrics.panelWidths(for: size)
        #expect(panels.left == size.height)
        #expect(panels.right == size.height * WelcomeLayoutMetrics.rightPanelRatio)
    }
}

