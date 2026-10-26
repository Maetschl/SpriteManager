import SwiftUI

struct SpriteSidebarAssetRow: View {
    @ObservedObject var document: ProjectDocument
    let asset: SpriteAsset

    var body: some View {
        HStack(spacing: 8) {
            AssetThumbnail(document: document, asset: asset)
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name).lineLimit(1)
                Text("\(asset.width) × \(asset.height) px")
                    .font(.caption)
                    .foregroundStyle(AppPalette.muted)
            }
            Spacer(minLength: 4)
            if document.dirtyAssetIDs.contains(asset.id) {
                Circle()
                    .fill(.orange)
                    .frame(width: 7, height: 7)
                    .help("Unsaved sprite changes")
            }
        }
        .tag(asset.id)
        .padding(.vertical, 2)
    }
}
