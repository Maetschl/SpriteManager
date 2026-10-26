import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteManagerDocumentView: View {
    @StateObject private var viewModel: SpriteManagerDocumentViewModel

    init(document: ProjectDocument) {
        _viewModel = StateObject(wrappedValue: SpriteManagerDocumentViewModel(document: document))
    }

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeader(document: viewModel.document)
            Divider()
            TabView(selection: $viewModel.selectedTab) {
                SpritesWorkspace(document: viewModel.document, showingImporter: $viewModel.showingImporter)
                    .tabItem { Label("Sprites", systemImage: "square.grid.2x2") }
                    .tag(0)
                SheetsWorkspace(document: viewModel.document) { spriteID in
                    viewModel.selectSpriteForEditing(spriteID)
                }
                    .tabItem { Label("Spritesheets", systemImage: "rectangle.3.group") }
                    .tag(1)
                PaletteWorkspace(document: viewModel.document)
                    .tabItem { Label("Color Pallete", systemImage: "paintpalette") }
                    .tag(2)
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(AppPalette.window)
        .toolbar {
            ToolbarItemGroup {
                Button("Load Assets", systemImage: "square.and.arrow.down") { viewModel.showingImporter = true }
                Divider()
                Button("Undo", systemImage: "arrow.uturn.backward") { viewModel.undo() }
                    .disabled(!viewModel.canUndo)
                Button("Redo", systemImage: "arrow.uturn.forward") { viewModel.redo() }
                    .disabled(!viewModel.canRedo)
                Divider()
                Button("Save Changes", systemImage: "checkmark.circle.fill", action: viewModel.save)
                    .disabled(!viewModel.isDirty)
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingImporter,
            allowedContentTypes: [.png],
            allowsMultipleSelection: true
        ) { result in viewModel.importFiles(result) }
        .alert("SpriteManager", isPresented: Binding(
            get: { viewModel.hasError },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", action: viewModel.clearError)
        } message: {
            Text(viewModel.errorText)
        }
        .alert("Library conflict", isPresented: Binding(
            get: { !viewModel.document.conflictAssetIDs.isEmpty },
            set: { if !$0 { viewModel.resolveConflict(useProjectVersion: false) } }
        )) {
            Button("Use Project Version") {
                viewModel.resolveConflict(useProjectVersion: true)
            }
            Button("Keep Library Version", role: .cancel) {
                viewModel.resolveConflict(useProjectVersion: false)
            }
        } message: {
            Text(viewModel.conflictText)
        }
        .onChange(of: viewModel.document.project.name) { _, _ in viewModel.projectNameDidChange() }
        .overlay {
            WindowCloseGuard(document: viewModel.document)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
    }
}

