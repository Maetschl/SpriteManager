import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WelcomeActionButton: View {
    let title: String
    let systemImage: String
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: max(14, 19 * scale), weight: .medium))
                    .frame(width: max(20, 24 * scale))
                Text(title)
                    .font(.system(size: max(12, 16 * scale), weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, max(12, 18 * scale))
            .frame(height: max(36, 54 * scale))
            .background(Color.white.opacity(0.08), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

