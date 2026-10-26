import Foundation
import SwiftUI

@MainActor
final class SpriteSidebarViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var search = ""
    @Published var isTargeted = false
    @Published var unassignedExpanded = true
    @Published var assignedExpanded = true

    init(document: ProjectDocument) {
        self.document = document
    }

    var filteredAssets: [SpriteAsset] {
        document.availableAssets.values
            .filter { asset in
                search.isEmpty
                    || asset.name.localizedCaseInsensitiveContains(search)
                    || asset.id.uuidString.localizedCaseInsensitiveContains(search)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var assignedAssets: [SpriteAsset] {
        filteredAssets.filter { document.assignedAssetIDs.contains($0.id) }
    }

    var unassignedAssets: [SpriteAsset] {
        filteredAssets.filter { !document.assignedAssetIDs.contains($0.id) }
    }

    var emptyTitle: String {
        search.isEmpty ? "Your library is empty" : "No matches"
    }

    var emptyDescription: String {
        search.isEmpty ? "Import PNGs to start building your sprite library." : "Try a different name or UUID."
    }

    var emptySystemImage: String {
        search.isEmpty ? "photo.on.rectangle" : "magnifyingglass"
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            guard let contents = try? Data(contentsOf: url) else {
                continue
            }
            document.importPNG(data: contents, originalName: url.lastPathComponent)
        }
    }
}
