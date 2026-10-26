import Foundation

struct ColorPalette: Codable, Hashable, Sendable {
    static let currentAlgorithmVersion = 1

    var algorithmVersion: Int = Self.currentAlgorithmVersion
    var colors: [PaletteColor]
    var aliases: [PaletteAlias]

    init(colors: [PaletteColor] = [], aliases: [PaletteAlias] = []) {
        self.colors = colors
        self.aliases = aliases
    }

    func outputColor(for source: PaletteRGBColor) -> PaletteRGBColor? {
        let colorsByID = Dictionary(uniqueKeysWithValues: colors.map { ($0.id, $0) })
        var visited = Set<UUID>()
        var currentID = colors.first(where: { $0.source == source })?.id

        if currentID == nil {
            currentID = aliases.first(where: { $0.source == source })?.targetColorID
        }

        while let id = currentID, let color = colorsByID[id] {
            guard visited.insert(id).inserted else { return nil }
            return color.output
        }
        return nil
    }

    func orderedBySimilarity() -> ColorPalette {
        guard colors.count > 1 else { return self }
        var remaining = colors
        var ordered: [PaletteColor] = []
        let first = remaining.min {
            let left = PaletteColorMath.okLab($0.output)
            let right = PaletteColorMath.okLab($1.output)
            if left.l != right.l { return left.l < right.l }
            return $0.output.hex < $1.output.hex
        }!
        ordered.append(first)
        remaining.removeAll { $0.id == first.id }

        while let previous = ordered.last, !remaining.isEmpty {
            let next = remaining.min {
                let distance = PaletteColorMath.distance(previous.output, $0.output)
                let otherDistance = PaletteColorMath.distance(previous.output, $1.output)
                if distance != otherDistance { return distance < otherDistance }
                return $0.output.hex < $1.output.hex
            }!
            ordered.append(next)
            remaining.removeAll { $0.id == next.id }
        }

        var result = self
        result.colors = ordered
        return result
    }
}

