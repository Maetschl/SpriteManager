import AppKit
import Foundation
import SwiftUI

@MainActor
final class SheetInspectorViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var assetSearch = ""

    init(document: ProjectDocument) {
        self.document = document
    }

    var filteredAssets: [SpriteAsset] {
        document.availableAssets.values
            .filter { assetSearch.isEmpty || $0.name.localizedCaseInsensitiveContains(assetSearch) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func updateName(_ sheetID: UUID, value: String) {
        document.updateSheet(sheetID, name: value)
    }

    func updateWidth(_ sheetID: UUID, value: Int) {
        document.updateSheet(sheetID, width: value)
    }

    func updateHeight(_ sheetID: UUID, value: Int) {
        document.updateSheet(sheetID, height: value)
    }

    func updateGridSize(_ sheetID: UUID, value: Int) {
        document.updateSheet(sheetID, gridSize: value)
    }

    func addSprite(_ spriteID: UUID, to sheetID: UUID) {
        document.addSprite(spriteID, to: sheetID)
    }

    func removePlacement(_ placementID: UUID, from sheetID: UUID) {
        document.removePlacement(sheetID: sheetID, placementID: placementID)
    }

    func movePlacement(_ placement: SpritePlacement, in sheetID: UUID, x: Int? = nil, y: Int? = nil) {
        let current = document.selectedSheet?.placements.first(where: { $0.id == placement.id }) ?? placement
        _ = document.movePlacement(
            sheetID: sheetID,
            placementID: placement.id,
            x: x ?? current.x,
            y: y ?? current.y
        )
    }

    func shiftSprite(_ spriteID: UUID, dx: Int, dy: Int) {
        document.shiftAsset(spriteID, dx: dx, dy: dy)
    }

    func updateBorder(_ sheet: SpriteSheet, enabled: Bool? = nil, color: Color? = nil) {
        var border = sheet.borderEffect
        if let enabled {
            border.enabled = enabled
        }
        if let color {
            let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .white
            border.color = RGBAColor(
                r: Double(nsColor.redComponent),
                g: Double(nsColor.greenComponent),
                b: Double(nsColor.blueComponent),
                a: Double(nsColor.alphaComponent)
            )
        }
        document.updateSheet(sheet.id, border: border)
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
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try document.export(sheet: sheet, to: url)
        } catch {
            document.errorMessage = error.localizedDescription
        }
    }
}
