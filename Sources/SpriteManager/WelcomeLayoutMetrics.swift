import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum WelcomeLayoutMetrics {
    static let referenceBase: CGFloat = 460
    static let rightPanelRatio: CGFloat = 3.0 / 5.0
    static let contentHeight: CGFloat = referenceBase * 2
    static let closeButtonInset: CGFloat = 10
    static let brandSpacing: CGFloat = 18
    static let actionSpacing: CGFloat = 14
    static let actionHorizontalPadding: CGFloat = 72
    static let actionBottomPadding: CGFloat = 66

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

