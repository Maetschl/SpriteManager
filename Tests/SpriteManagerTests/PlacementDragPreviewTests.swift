import Testing
import Foundation
@testable import SpriteManager

@Suite("PlacementDragPreview")
struct PlacementDragPreviewTests {
    @Test func storesPlacementPreview() {
        let id = UUID()
        #expect(PlacementDragPreview(placementID: id, x: 2, y: 4, isValid: true).placementID == id)
    }
}
