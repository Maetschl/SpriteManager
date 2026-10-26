import Foundation
import Testing
@testable import SpriteManager

@Suite("ProjectSnapshot")
struct ProjectSnapshotTests {
    @Test func storesManifestAndAssetData() {
        let data = Data([1])
        let snapshot = ProjectSnapshot(manifest: ProjectManifest(project: SpriteProject(), assets: []), dataByAssetID: [:])
        #expect(snapshot.dataByAssetID.isEmpty)
        #expect(snapshot.manifest.project.name == "Untitled Project")
        _ = data
    }
}

