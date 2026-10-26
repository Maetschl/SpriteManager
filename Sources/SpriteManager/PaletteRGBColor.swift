import SwiftUI

struct PaletteRGBColor: Codable, Hashable, Sendable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    init?(hex: String) {
        let normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard normalized.count == 6, let value = UInt32(normalized, radix: 16) else { return nil }
        self.init(
            r: UInt8((value >> 16) & 0xFF),
            g: UInt8((value >> 8) & 0xFF),
            b: UInt8(value & 0xFF)
        )
    }

    var hex: String { String(format: "#%02X%02X%02X", r, g, b) }

    var swiftColor: Color {
        Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

