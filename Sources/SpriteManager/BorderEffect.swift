import Foundation

struct BorderEffect: Codable, Hashable, Sendable {
    var enabled = false
    var color = RGBAColor(r: 1, g: 1, b: 1, a: 1)
    var thickness = BorderEffect.defaultThickness
    var algorithmVersion = BorderEffect.currentAlgorithmVersion
}

