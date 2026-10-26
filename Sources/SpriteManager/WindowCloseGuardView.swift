import AppKit

@MainActor
final class WindowCloseGuardView: NSView {
    var onWindowChange: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window { onWindowChange?(window) }
    }
}
