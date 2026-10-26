import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PaletteColorCard: View {
    let color: PaletteColor
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7)
                .fill(color.output.swiftColor)
                .frame(width: 38, height: 38)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(color.output.hex)
                    .font(.subheadline.monospaced().weight(.semibold))
                if color.source != color.output {
                    Text("from \(color.source.hex)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(AppPalette.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
        }
    }
}

