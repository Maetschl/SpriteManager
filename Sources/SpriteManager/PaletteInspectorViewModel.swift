import AppKit
import Foundation
import SwiftUI

@MainActor
final class PaletteInspectorViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var hexText = ""
    @Published var colorToDelete: PaletteColor?

    init(document: ProjectDocument) {
        self.document = document
    }

    func selectedColor(_ id: UUID?) -> PaletteColor? {
        guard let id else {
            return nil
        }
        return document.effectivePalette?.colors.first(where: { $0.id == id })
    }

    var canDeleteSelectedColor: Bool {
        (document.effectivePalette?.colors.count ?? 0) > 1
    }

    func updateColor(_ colorID: UUID, color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .white
        document.updatePaletteColor(
            colorID,
            output: PaletteRGBColor(
                r: UInt8(max(0, min(255, Int(nsColor.redComponent * 255)))),
                g: UInt8(max(0, min(255, Int(nsColor.greenComponent * 255)))),
                b: UInt8(max(0, min(255, Int(nsColor.blueComponent * 255))))
            )
        )
    }

    func updateColor(_ colorID: UUID, hex: String) {
        hexText = hex
        if let parsed = PaletteRGBColor(hex: hex) {
            document.updatePaletteColor(colorID, output: parsed)
        }
    }

    func syncHex(for id: UUID?) {
        hexText = selectedColor(id)?.output.hex ?? ""
    }

    func deleteSelectedColor() {
        guard let colorToDelete else {
            return
        }
        document.deletePaletteColor(colorToDelete.id)
        self.colorToDelete = nil
    }
}
