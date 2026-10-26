import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
struct WindowCloseGuard: NSViewRepresentable {
    @ObservedObject var document: ProjectDocument

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document)
    }

    func makeNSView(context: Context) -> GuardView {
        let view = GuardView()
        view.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: GuardView, context: Context) {
        context.coordinator.document = document
        if let window = nsView.window {
            context.coordinator.attach(to: window)
        }
    }

    final class GuardView: NSView {
        var onWindowChange: ((NSWindow) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { onWindowChange?(window) }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSWindowDelegate {
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
}

