import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteSidebar: View {
    @ObservedObject var document: ProjectDocument
    @Binding var showingImporter: Bool
    @StateObject private var viewModel: SpriteSidebarViewModel

    init(document: ProjectDocument, showingImporter: Binding<Bool>) {
        self.document = document
        _showingImporter = showingImporter
        _viewModel = StateObject(wrappedValue: SpriteSidebarViewModel(document: document))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Library", systemImage: "square.grid.2x2")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.filteredAssets.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
            SearchField(text: $viewModel.search, placeholder: "Search by name or UUID")
            List(selection: $document.selectedSpriteID) {
                DisclosureGroup(isExpanded: $viewModel.assignedExpanded) {
                    ForEach(viewModel.assignedAssets) { asset in
                        SpriteSidebarAssetRow(document: document, asset: asset)
                    }
                } label: {
                    SpriteSidebarSectionLabel(
                        title: "Assigned",
                        count: viewModel.assignedAssets.count,
                        icon: "square.stack.3d.up"
                    )
                }
                DisclosureGroup(isExpanded: $viewModel.unassignedExpanded) {
                    ForEach(viewModel.unassignedAssets) { asset in
                        SpriteSidebarAssetRow(document: document, asset: asset)
                    }
                } label: {
                    SpriteSidebarSectionLabel(
                        title: "Unassigned",
                        count: viewModel.unassignedAssets.count,
                        icon: "tray"
                    )
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if viewModel.filteredAssets.isEmpty {
                    ContentUnavailableView(
                        viewModel.emptyTitle,
                        systemImage: viewModel.emptySystemImage,
                        description: Text(viewModel.emptyDescription)
                    )
                        .allowsHitTesting(false)
                }
            }
            ImportDropZone(showingImporter: $showingImporter, isTargeted: $viewModel.isTargeted, importURLs: viewModel.importFiles)
        }
        .padding(.top, 4)
        .background(.clear)
    }
}

