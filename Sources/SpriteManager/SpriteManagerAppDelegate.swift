import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
final class SpriteManagerAppDelegate: NSObject, NSApplicationDelegate {
    private var documentObserver: NSObjectProtocol?
    private var windowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        documentObserver = NotificationCenter.default.addObserver(
            forName: .spriteManagerDocumentWindowsDidChange,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                WelcomeWindowController.shared.syncWithDocuments()
            }
        }

        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if NSDocumentController.shared.documents.contains(where: { $0.fileURL != nil }) {
                    WelcomeWindowController.shared.close()
                }
            }
        }

        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let controller = NSDocumentController.shared
                let hasUntitledDocument = controller.documents.contains { $0.fileURL == nil }
                let hasSavedDocument = controller.documents.contains { $0.fileURL != nil }
                if hasUntitledDocument && !hasSavedDocument {
                    for window in NSApp.windows {
                        window.orderOut(nil)
                    }
                    WelcomeWindowController.shared.show()
                } else {
                    WelcomeWindowController.shared.syncWithDocuments()
                }
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if NSDocumentController.shared.documents.isEmpty {
            WelcomeWindowController.shared.show()
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag || NSDocumentController.shared.documents.isEmpty {
            WelcomeWindowController.shared.show()
        }
        return true
    }

}

