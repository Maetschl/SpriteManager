import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PixelGrid: View {
    let width: Int
    let height: Int
    let zoom: CGFloat

    var body: some View {
        Canvas { context, _ in
            var path = Path()
            for x in 0...width {
                let px = CGFloat(x) * zoom
                path.move(to: CGPoint(x: px, y: 0))
                path.addLine(to: CGPoint(x: px, y: CGFloat(height) * zoom))
            }
            for y in 0...height {
                let py = CGFloat(y) * zoom
                path.move(to: CGPoint(x: 0, y: py))
                path.addLine(to: CGPoint(x: CGFloat(width) * zoom, y: py))
            }
            context.stroke(path, with: .color(.black.opacity(0.15)), lineWidth: 1)
        }
    }
}

