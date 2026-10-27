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

    @Test func filtersByTagAndDimensions() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let library = LibraryStore(rootURL: root)
        let data = try PixelBuffer(width: 2, height: 3, pixels: [UInt8](repeating: 255, count: 2 * 3 * 4)).pngData()
        let asset = SpriteAsset(
            name: "Knight",
            width: 2,
            height: 3,
            contentHash: PixelData.sha256(data),
            originalFileName: "knight.png",
            tags: ["Characters"]
        )
        try library.register(asset, data: data)
        let viewModel = SpriteSidebarViewModel(document: ProjectDocument(library: library))

        viewModel.selectedTag = "characters"
        viewModel.widthText = "2"
        viewModel.heightText = "3"
        #expect(viewModel.filteredAssets.map(\.id) == [asset.id])

        viewModel.widthText = "4"
        #expect(viewModel.filteredAssets.isEmpty)
    }
}

