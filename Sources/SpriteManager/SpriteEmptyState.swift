import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteEmptyState: View {
    @ObservedObject var document: ProjectDocument
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.tint)
            Text(document.availableAssets.isEmpty ? "Build your sprite library" : "Choose a sprite")
                .font(.title3.weight(.semibold))
            Text(
                document.availableAssets.isEmpty
                    ? "Import PNGs to inspect and nudge their pixels inside a fixed frame."
                    : "Select an asset from the library to inspect it, or import new PNGs to add them."
            )
                .font(.callout)
                .foregroundStyle(AppPalette.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
            Button("Load Assets", systemImage: "square.and.arrow.down") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

