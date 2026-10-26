import Foundation
import Testing
@testable import SpriteManager

@Suite("SpriteCanvasViewModel")
@MainActor
struct SpriteCanvasViewModelTests {
    @Test func usesPixelEditorZoomDefaults() {
        let document = ProjectDocument(library: LibraryStore(rootURL: FileManager.default.temporaryDirectory))
        let viewModel = SpriteCanvasViewModel(document: document)
        #expect(viewModel.zoom == SpriteCanvasConstants.defaultZoom)
        #expect(viewModel.gridEnabled)
    }
}

