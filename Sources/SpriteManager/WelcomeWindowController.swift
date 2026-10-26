import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class WelcomeWindowController: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = WelcomeWindowController()

    @Published var errorMessage: String?
    let recentProjects = RecentProjectsStore()

    private var window: NSWindow?

    func syncWithDocuments() {
        recentProjects.refresh()
        let hasBackedProject = NSDocumentController.shared.documents.contains { $0.fileURL != nil }
        if !hasBackedProject {
            show()
        } else {
            close()
        }
    }

    func show() {
        recentProjects.refresh()
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let availableSize = NSScreen.main?.visibleFrame.size ?? CGSize(
            width: WelcomeLayoutMetrics.referenceBase * WelcomeLayoutMetrics.totalWidthRatio,
            height: WelcomeLayoutMetrics.referenceBase
        )
        let size = WelcomeLayoutMetrics.windowSize(for: availableSize)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "Welcome to SpriteManager"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.styleMask.remove(.resizable)
        window.minSize = size
        window.maxSize = size
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentView = NSHostingView(rootView: WelcomeView(controller: self, recentProjects: recentProjects))
        window.delegate = self
        window.center()
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.orderOut(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    func createProject() {
        close()
        NSDocumentController.shared.newDocument(nil)
        DispatchQueue.main.async {
            self.syncWithDocuments()
        }
    }

    func openExistingProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ProjectDocument.readableContentTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.openProject(at: url)
        }
    }

    func openProject(at url: URL) {
        errorMessage = nil
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { [weak self] _, _, error in
            guard let error else { return }
            self?.errorMessage = error.localizedDescription
            self?.show()
        }
    }
}

