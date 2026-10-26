import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 8
            for y in stride(from: CGFloat(0), to: size.height, by: cell) {
                for x in stride(from: CGFloat(0), to: size.width, by: cell) {
                    let even = Int(x / cell + y / cell).isMultiple(of: 2)
                    context.fill(Path(CGRect(x: x, y: y, width: cell, height: cell)), with: .color(even ? .white : .gray.opacity(0.2)))
                }
            }
        }
    }
}

