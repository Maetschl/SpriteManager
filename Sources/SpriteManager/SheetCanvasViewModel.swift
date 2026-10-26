import AppKit
import Foundation

@MainActor
final class SheetCanvasViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var zoom: CGFloat = SheetCanvasConstants.defaultZoom
    @Published var dragPreview: PlacementDragPreview?

    init(document: ProjectDocument) {
        self.document = document
    }

    func updateDrag(
        sheet: SpriteSheet,
        placement: SpritePlacement,
        translation: CGSize
    ) {
        let offsetX = Int(round(translation.width / zoom))
        let offsetY = Int(round(translation.height / zoom))
        let rawX = placement.x + offsetX
        let rawY = placement.y + offsetY
        let position = document.snappedPlacementPosition(
            sheetID: sheet.id,
            placementID: placement.id,
            x: rawX,
            y: rawY
        )
        let displayX = position?.x ?? rawX
        let displayY = position?.y ?? rawY
        dragPreview = PlacementDragPreview(
            placementID: placement.id,
            x: displayX,
            y: displayY,
            isValid: document.canMovePlacement(
                sheetID: sheet.id,
                placementID: placement.id,
                x: displayX,
                y: displayY
            )
        )
    }

    func finishDrag(sheet: SpriteSheet, placement: SpritePlacement, translation: CGSize) {
        let dx = Int(round(translation.width / zoom))
        let dy = Int(round(translation.height / zoom))
        _ = document.movePlacement(
            sheetID: sheet.id,
            placementID: placement.id,
            x: placement.x + dx,
            y: placement.y + dy
        )
        dragPreview = nil
    }

    func export(_ sheet: SpriteSheet) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Export Here"
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        do {
            try document.export(sheet: sheet, to: url)
        } catch {
            document.errorMessage = error.localizedDescription
        }
    }

    func createSheet() {
        document.createSheet()
    }

    func removePlacement(sheetID: UUID, placementID: UUID) {
        document.removePlacement(sheetID: sheetID, placementID: placementID)
    }
}

