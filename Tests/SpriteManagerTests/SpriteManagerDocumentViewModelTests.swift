import Foundation
import Testing
@testable import SpriteManager

@Suite("SpriteManagerDocumentViewModel")
@MainActor
struct SpriteManagerDocumentViewModelTests {
    @Test func startsOnSpritesTabWithoutImporter() {
        let viewModel = SpriteManagerDocumentViewModel(document: ProjectDocument(library: LibraryStore(rootURL: FileManager.default.temporaryDirectory)))
        #expect(viewModel.selectedTab == 0)
        #expect(!viewModel.showingImporter)
    }
}

