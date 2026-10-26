import Testing
@testable import SpriteManager

@Suite("ProjectEditState")
struct ProjectEditStateTests {
    @Test func storesEmptyEditState() {
        let state = ProjectEditState(project: SpriteProject(), assets: [:], pixelData: [:], dirtyAssetIDs: [], pendingPalette: nil)
        #expect(state.assets.isEmpty)
        #expect(state.pendingPalette == nil)
    }
}

