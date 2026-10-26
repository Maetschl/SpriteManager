import Foundation
import Testing
@testable import SpriteManager

@Suite("SpriteSidebarViewModel")
@MainActor
struct SpriteSidebarViewModelTests {
    @Test func startsExpandedWithEmptySearch() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let document = ProjectDocument(library: LibraryStore(rootURL: root))
        let viewModel = SpriteSidebarViewModel(document: document)
        #expect(viewModel.search.isEmpty)
        #expect(viewModel.assignedExpanded)
        #expect(viewModel.unassignedExpanded)
        #expect(viewModel.filteredAssets.isEmpty)
    }
}

