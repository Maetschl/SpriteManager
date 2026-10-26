import AppKit
import Foundation

@MainActor
final class AssetThumbnailViewModel: ObservableObject {
    let document: ProjectDocument

    init(document: ProjectDocument) {
        self.document = document
    }

    func image(for assetID: UUID) -> NSImage? {
        document.image(for: assetID)
    }
}
