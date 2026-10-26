import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AssetThumbnail: View {
    @ObservedObject var document: ProjectDocument
    let asset: SpriteAsset
    @StateObject private var viewModel: AssetThumbnailViewModel

    init(document: ProjectDocument, asset: SpriteAsset) {
        self.document = document
        self.asset = asset
        _viewModel = StateObject(wrappedValue: AssetThumbnailViewModel(document: document))
    }

    var body: some View {
        Group {
            if let image = viewModel.image(for: asset.id) {
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

