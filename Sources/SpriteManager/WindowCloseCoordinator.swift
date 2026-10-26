import AppKit

@MainActor
final class WindowCloseCoordinator: NSObject, NSWindowDelegate {
    var document: ProjectDocument
    weak var attachedWindow: NSWindow?

    init(document: ProjectDocument) {
        self.document = document
    }

    func attach(to window: NSWindow) {
        window.styleMask.remove(.fullSizeContentView)
        window.styleMask.formUnion([.titled, .closable, .miniaturizable, .resizable])
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.title = document.project.name
        guard attachedWindow !== window else { return }
        attachedWindow = window
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard document.isDirty else { return true }

        let alert = NSAlert()
        alert.messageText = "Unsaved Changes"
        alert.informativeText = "Save your project before closing this window?"
        alert.addButton(withTitle: "Save Changes")
        alert.addButton(withTitle: "Discard Changes")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
            return false
        case .alertSecondButtonReturn:
            document.isDirty = false
            return true
        default:
            return false
        }
    }

    func windowWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .spriteManagerDocumentWindowsDidChange, object: nil)
    }
}
