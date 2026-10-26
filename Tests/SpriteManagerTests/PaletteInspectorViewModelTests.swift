import Foundation
import Testing
@testable import SpriteManager

@Suite("PaletteInspectorViewModel")
@MainActor
struct PaletteInspectorViewModelTests {
    @Test func hasNoSelectionForMissingID() {
        let document = ProjectDocument(library: LibraryStore(rootURL: FileManager.default.temporaryDirectory))
        let viewModel = PaletteInspectorViewModel(document: document)
        #expect(viewModel.selectedColor(nil) == nil)
        #expect(viewModel.hexText.isEmpty)
    }
}

