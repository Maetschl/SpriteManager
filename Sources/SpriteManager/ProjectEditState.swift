import Foundation

struct ProjectEditState {
    let project: SpriteProject
    let assets: [UUID: SpriteAsset]
    let pixelData: [UUID: Data]
    let dirtyAssetIDs: Set<UUID>
    let pendingPalette: ColorPalette?
}
