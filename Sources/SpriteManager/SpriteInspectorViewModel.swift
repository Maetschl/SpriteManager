import AppKit
import Foundation
import SwiftUI

@MainActor
final class SpriteInspectorViewModel: ObservableObject {
    let document: ProjectDocument

    init(document: ProjectDocument) {
        self.document = document
    }

    func nameBinding(for asset: SpriteAsset) -> Binding<String> {
        Binding(
            get: { [document] in document.asset(for: asset.id)?.name ?? asset.name },
            set: { [document] value in document.updateAssetName(asset.id, name: value) }
        )
    }

    func includeInProject(_ assetID: UUID) {
        document.includeAssetInProject(assetID)
    }

    func copyUUID(_ assetID: UUID) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(assetID.uuidString, forType: .string)
    }
}
