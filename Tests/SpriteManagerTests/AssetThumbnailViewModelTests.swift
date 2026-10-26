import Foundation
import Testing
@testable import SpriteManager

@Suite("AssetThumbnailViewModel")
@MainActor
struct AssetThumbnailViewModelTests {
    @Test func returnsNilForUnknownAsset() {
        let viewModel = AssetThumbnailViewModel(document: ProjectDocument())
        #expect(viewModel.image(for: UUID()) == nil)
    }
}
