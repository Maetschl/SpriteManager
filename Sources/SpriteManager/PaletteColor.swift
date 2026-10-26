import Foundation

struct PaletteColor: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let source: PaletteRGBColor
    var output: PaletteRGBColor

    init(id: UUID = UUID(), source: PaletteRGBColor, output: PaletteRGBColor? = nil) {
        self.id = id
        self.source = source
        self.output = output ?? source
    }
}

