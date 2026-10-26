import Foundation
import Testing
@testable import SpriteManager

@Suite("SheetCanvasViewModel")
@MainActor
struct SheetCanvasViewModelTests {
    @Test func usesCompositionZoomDefaults() {
        let document = ProjectDocument(library: LibraryStore(rootURL: FileManager.default.temporaryDirectory))
        let viewModel = SheetCanvasViewModel(document: document)
        #expect(viewModel.zoom == SheetCanvasConstants.defaultZoom)
        #expect(viewModel.dragPreview == nil)
    }
}

