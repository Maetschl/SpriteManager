import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AssetThumbnail: View {
    @ObservedObject var document: ProjectDocument
    let asset: SpriteAsset

    var body: some View {
        Group {
            if let image = document.image(for: asset.id) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 42, height: 42)
        .background(Checkerboard())
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

