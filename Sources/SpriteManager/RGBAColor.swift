import SwiftUI

struct RGBAColor: Codable, Hashable, Sendable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    var swiftColor: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

