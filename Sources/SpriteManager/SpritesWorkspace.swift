import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpritesWorkspace: View {
    @ObservedObject var document: ProjectDocument
    @Binding var showingImporter: Bool

    var body: some View {
        NavigationSplitView {
            SpriteSidebar(document: document, showingImporter: $showingImporter)
                .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 420)
        } content: {
            SpriteCanvas(document: document, showingImporter: $showingImporter)
                .navigationSplitViewColumnWidth(min: 420, ideal: 640, max: 1200)
        } detail: {
            SpriteInspector(document: document)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 720)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

