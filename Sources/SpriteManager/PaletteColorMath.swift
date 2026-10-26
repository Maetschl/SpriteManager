import Foundation

enum PaletteColorMath {
    static func distance(_ lhs: PaletteRGBColor, _ rhs: PaletteRGBColor) -> Double {
        let left = okLab(lhs)
        let right = okLab(rhs)
        return pow(left.l - right.l, 2) + pow(left.a - right.a, 2) + pow(left.b - right.b, 2)
    }

    static func okLab(_ color: PaletteRGBColor) -> OKLabColor {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        func cubeRoot(_ value: Double) -> Double {
            value >= 0 ? pow(value, 1.0 / 3.0) : -pow(-value, 1.0 / 3.0)
        }

        let r = linear(Double(color.r) / 255)
        let g = linear(Double(color.g) / 255)
        let b = linear(Double(color.b) / 255)
        let l = cubeRoot(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cubeRoot(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cubeRoot(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return OKLabColor(
            l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }
}

