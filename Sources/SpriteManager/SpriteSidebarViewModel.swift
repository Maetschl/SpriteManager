import Foundation
import SwiftUI

enum SpriteUsageFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case assigned
    case unassigned

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct SpriteSearchFilter: Hashable {
    var tag: String?
    var width: Int?
    var height: Int?
    var usage: SpriteUsageFilter
    var color: PaletteRGBColor?

    static let empty = SpriteSearchFilter(tag: nil, width: nil, height: nil, usage: .all, color: nil)
}

@MainActor
final class SpriteSidebarViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var search = ""
    @Published var isTargeted = false
    @Published var unassignedExpanded = true
    @Published var assignedExpanded = true
    @Published var selectedCollectionID: UUID?
    @Published var selectedTag: String?
    @Published var widthText = ""
    @Published var heightText = ""
    @Published var usageFilter: SpriteUsageFilter = .all
    @Published var colorText = ""

    init(document: ProjectDocument) {
        self.document = document
    }

    var filteredAssets: [SpriteAsset] {
        document.availableAssets.values
            .filter { asset in
                let matchesText = search.isEmpty
                    || asset.name.localizedCaseInsensitiveContains(search)
                    || asset.id.uuidString.localizedCaseInsensitiveContains(search)
                let matchesTag = selectedTag == nil || asset.tags.contains(selectedTag!)
                let matchesWidth = widthText.isEmpty || Int(widthText) == asset.width
                let matchesHeight = heightText.isEmpty || Int(heightText) == asset.height
                let matchesUsage: Bool = switch usageFilter {
                case .all: true
                case .assigned: document.assignedAssetIDs.contains(asset.id)
                case .unassigned: !document.assignedAssetIDs.contains(asset.id)
                }
                let matchesColor = colorText.isEmpty || (PaletteRGBColor(hex: colorText).map { document.assetContainsColor(asset.id, color: $0) } ?? false)
                let matchesCollection = selectedCollectionID == nil || document.project.collections.first(where: { $0.id == selectedCollectionID })?.assetIDs.contains(asset.id) == true
                return matchesText && matchesTag && matchesWidth && matchesHeight && matchesUsage && matchesColor && matchesCollection
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var allTags: [String] {
        Array(Set(document.availableAssets.values.flatMap(\.tags))).sorted()
    }

    var collections: [SpriteCollection] {
        document.project.collections.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var hasFilters: Bool {
        !search.isEmpty || selectedTag != nil || !widthText.isEmpty || !heightText.isEmpty || usageFilter != .all || !colorText.isEmpty || selectedCollectionID != nil
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

    func clearFilters() {
        search = ""
        selectedTag = nil
        widthText = ""
        heightText = ""
        usageFilter = .all
        colorText = ""
        selectedCollectionID = nil
    }

    func createCollection() {
        document.createCollection()
    }

    func deleteCollection(_ collection: SpriteCollection) {
        document.deleteCollection(collection.id)
        if selectedCollectionID == collection.id { selectedCollectionID = nil }
    }

    func renameSelectedCollection(_ name: String) {
        guard let selectedCollectionID else { return }
        document.renameCollection(selectedCollectionID, name: name)
    }
}
