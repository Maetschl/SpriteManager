import Foundation
import Testing
@testable import SpriteManager

@Suite("PalettePreviewImageViewModel")
@MainActor
struct PalettePreviewImageViewModelTests {
    @Test func centersImageInsidePreview() {
        let document = ProjectDocument(library: LibraryStore(rootURL: FileManager.default.temporaryDirectory))
        let viewModel = PalettePreviewImageViewModel(document: document)
        let rect = viewModel.imageRect(
            in: CGSize(width: 200, height: 100),
            sheet: SpriteSheet(name: "Sheet", canvasWidth: 100, canvasHeight: 50)
        )
        #expect(rect.midX == 100)
        #expect(rect.midY == 50)
    }
}

