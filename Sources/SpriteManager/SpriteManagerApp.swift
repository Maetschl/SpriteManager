import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct SpriteManagerApp: App {
    @NSApplicationDelegateAdaptor(SpriteManagerAppDelegate.self) private var appDelegate

    var body: some Scene {
        DocumentGroup(viewing: ProjectDocument.self) { file in
            SpriteManagerDocumentView(document: file.document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    WelcomeWindowController.shared.createProject()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            CommandGroup(after: .windowArrangement) {
                Button("Welcome to SpriteManager") {
                    WelcomeWindowController.shared.show()
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
            }
        }
    }
}

