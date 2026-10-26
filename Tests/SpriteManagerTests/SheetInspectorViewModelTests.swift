import Foundation
import Testing
@testable import SpriteManager

@Suite("SheetInspectorViewModel")
@MainActor
struct SheetInspectorViewModelTests {
    @Test func filtersAssetsByName() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let document = ProjectDocument(library: LibraryStore(rootURL: root))
        let viewModel = SheetInspectorViewModel(document: document)
        #expect(viewModel.filteredAssets.isEmpty)
        viewModel.assetSearch = "hero"
        #expect(viewModel.filteredAssets.isEmpty)
    }
}

