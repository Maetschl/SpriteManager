import Foundation
import Testing
@testable import SpriteManager

@Suite("PaletteWorkspaceViewModel")
@MainActor
struct PaletteWorkspaceViewModelTests {
    @Test func resetsPreviewTransformWhenSelectingSheet() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let document = ProjectDocument(library: LibraryStore(rootURL: root))
        let viewModel = PaletteWorkspaceViewModel(document: document)
        viewModel.previewZoom = 4
        viewModel.previewOffset = CGSize(width: 20, height: 10)
        let sheet = SpriteSheet(name: "Preview")
        document.project.sheets = [sheet]
        viewModel.selectSheet(sheet.id)
        #expect(viewModel.previewZoom == 1)
        #expect(viewModel.previewOffset == .zero)
    }
}

