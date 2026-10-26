import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum WelcomeLayoutMetrics {
    static let referenceBase: CGFloat = 460
    static let rightPanelRatio: CGFloat = 3.0 / 5.0

    static var totalWidthRatio: CGFloat {
        1 + rightPanelRatio
    }

    static func base(for availableSize: CGSize) -> CGFloat {
        min(referenceBase, availableSize.height, availableSize.width / totalWidthRatio)
    }

    static func windowSize(for availableSize: CGSize) -> CGSize {
        let base = self.base(for: availableSize)
        return CGSize(width: base * totalWidthRatio, height: base)
    }

    static func panelWidths(for windowSize: CGSize) -> (left: CGFloat, right: CGFloat) {
        (left: windowSize.height, right: windowSize.height * rightPanelRatio)
    }
}

