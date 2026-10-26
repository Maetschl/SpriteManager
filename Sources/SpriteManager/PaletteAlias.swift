import Foundation

struct PaletteAlias: Codable, Hashable, Sendable {
    let source: PaletteRGBColor
    var targetColorID: UUID
}

