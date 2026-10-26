import AppKit
import Foundation
import SwiftUI

@MainActor
final class SpriteManagerDocumentViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var showingImporter = false
    @Published var importError: String?
    @Published var selectedTab = 0

    init(document: ProjectDocument) {
        self.document = document
    }

    var hasError: Bool {
        document.errorMessage != nil || importError != nil
    }

    var errorText: String {
        document.errorMessage ?? importError ?? "Unknown error"
    }

    var conflictText: String {
        guard let id = document.conflictAssetIDs.first, let asset = document.assets[id] else {
            return "A project sprite conflicts with the global library."
        }
        return asset.name + " (" + String(id.uuidString.prefix(8)) + ") exists in the global library with different pixels. Choose which version should become the shared source."
    }

    func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            for url in urls {
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do {
                    document.importPNG(data: try Data(contentsOf: url), originalName: url.lastPathComponent)
                } catch {
                    importError = error.localizedDescription
                }
            }
        case let .failure(error):
            importError = error.localizedDescription
        }
    }

    func clearError() {
        document.errorMessage = nil
        importError = nil
    }

    func save() {
        NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
    }

    func selectSpriteForEditing(_ spriteID: UUID) {
        document.selectedSpriteID = spriteID
        selectedTab = 0
    }

    func resolveConflict(useProjectVersion: Bool) {
        document.resolveNextConflict(useProjectVersion: useProjectVersion)
    }
}
