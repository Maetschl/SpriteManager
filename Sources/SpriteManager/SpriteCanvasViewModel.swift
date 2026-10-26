import Foundation
import SwiftUI
import AppKit

@MainActor
final class SpriteCanvasViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var zoom: CGFloat = SpriteCanvasConstants.defaultZoom
    @Published var dragPreview: PixelDragPreview?
    @Published var gridEnabled = true

    init(document: ProjectDocument) {
        self.document = document
    }

    var selectedAsset: SpriteAsset? { document.selectedAsset }

    func image(for assetID: UUID) -> NSImage? {
        document.image(for: assetID)
    }

    func updateDrag(translation: CGSize) {
        let dx = Int(round(translation.width / zoom))
        let dy = Int(round(translation.height / zoom))
        dragPreview = PixelDragPreview(dx: dx, dy: dy)
    }

    func finishDrag(translation: CGSize) {
        let dx = Int(round(translation.width / zoom))
        let dy = Int(round(translation.height / zoom))
        dragPreview = nil
        guard let id = document.selectedSpriteID, dx != 0 || dy != 0 else {
            return
        }
        document.shiftAsset(id, dx: dx, dy: dy)
    }
}

