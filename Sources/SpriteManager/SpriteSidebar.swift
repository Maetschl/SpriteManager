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

    private func assetRow(_ asset: SpriteAsset) -> some View {
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

    private func sectionLabel(_ title: String, count: Int, icon: String) -> some View {
        Label {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(AppPalette.muted)
            }
        } icon: {
            Image(systemName: icon)
        }
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
                    ForEach(viewModel.assignedAssets) { asset in assetRow(asset) }
                } label: {
                    sectionLabel("Assigned", count: viewModel.assignedAssets.count, icon: "square.stack.3d.up")
                }
                DisclosureGroup(isExpanded: $viewModel.unassignedExpanded) {
                    ForEach(viewModel.unassignedAssets) { asset in assetRow(asset) }
                } label: {
                    sectionLabel("Unassigned", count: viewModel.unassignedAssets.count, icon: "tray")
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if viewModel.filteredAssets.isEmpty {
                    ContentUnavailableView(viewModel.emptyTitle, systemImage: viewModel.emptySystemImage, description: Text(viewModel.emptyDescription))
                        .allowsHitTesting(false)
                }
            }
            ImportDropZone(showingImporter: $showingImporter, isTargeted: $viewModel.isTargeted, importURLs: viewModel.importFiles)
        }
        .padding(.top, 4)
        .background(.clear)
    }
}

