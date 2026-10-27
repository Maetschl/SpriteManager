import AppKit
import Foundation
import SwiftUI

@MainActor
final class SpriteInspectorViewModel: ObservableObject {
    let document: ProjectDocument

    init(document: ProjectDocument) {
        self.document = document
    }

    var selectedAsset: SpriteAsset? { document.selectedAsset }

    func isIncludedInProject(_ assetID: UUID) -> Bool {
        document.assets[assetID] != nil
    }

    func nameBinding(for asset: SpriteAsset) -> Binding<String> {
        Binding(
            get: { [document] in document.asset(for: asset.id)?.name ?? asset.name },
            set: { [document] value in document.updateAssetName(asset.id, name: value) }
        )
    }

    func tagsBinding(for asset: SpriteAsset) -> Binding<String> {
        Binding(
            get: { [document] in document.asset(for: asset.id)?.tags.joined(separator: ", ") ?? "" },
            set: { [document] value in
                document.updateAssetTags(asset.id, tags: value.split(separator: ",").map(String.init))
            }
        )
    }

    func includeInProject(_ assetID: UUID) {
        document.includeAssetInProject(assetID)
    }

    func isInCollection(_ assetID: UUID, collection: SpriteCollection) -> Bool {
        collection.assetIDs.contains(assetID)
    }

    func setCollection(_ collection: SpriteCollection, assetID: UUID, included: Bool) {
        document.setAsset(assetID, inCollection: collection.id, included: included)
    }

    func copyUUID(_ assetID: UUID) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(assetID.uuidString, forType: .string)
    }
}
