import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteSidebar: View {
    @ObservedObject var document: ProjectDocument
    @Binding var showingImporter: Bool
    @StateObject private var viewModel: SpriteSidebarViewModel
    @State private var filtersExpanded = false

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
            DisclosureGroup("Filters", isExpanded: $filtersExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Width", text: $viewModel.widthText)
                            .textFieldStyle(.roundedBorder)
                        Text("×")
                            .foregroundStyle(AppPalette.muted)
                        TextField("Height", text: $viewModel.heightText)
                            .textFieldStyle(.roundedBorder)
                    }
                    Picker("Usage", selection: $viewModel.usageFilter) {
                        ForEach(SpriteUsageFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    if !viewModel.allTags.isEmpty {
                        Picker("Tag", selection: $viewModel.selectedTag) {
                            Text("All tags").tag(Optional<String>.none)
                            ForEach(viewModel.allTags, id: \.self) { tag in
                                Text(tag).tag(Optional(tag))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    TextField("Color #RRGGBB", text: $viewModel.colorText)
                        .textFieldStyle(.roundedBorder)
                    if viewModel.hasFilters {
                        Button("Clear filters", systemImage: "xmark.circle") {
                            viewModel.clearFilters()
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
            }
            HStack {
                Label("Collections", systemImage: "folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.muted)
                Spacer()
                Button { viewModel.createCollection() } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Create collection")
            }
            if !viewModel.collections.isEmpty {
                Picker("Collection", selection: $viewModel.selectedCollectionID) {
                    Text("All sprites").tag(Optional<UUID>.none)
                    ForEach(viewModel.collections) { collection in
                        Text(collection.name).tag(Optional(collection.id))
                    }
                }
                .pickerStyle(.menu)
                .contextMenu {
                    if let selected = viewModel.collections.first(where: { $0.id == viewModel.selectedCollectionID }) {
                        Button("Delete (selected.name)", role: .destructive) {
                            viewModel.deleteCollection(selected)
                        }
                    }
                }
                if let selected = viewModel.collections.first(where: { $0.id == viewModel.selectedCollectionID }) {
                    HStack(spacing: 6) {
                        TextField("Collection name", text: Binding(
                            get: { selected.name },
                            set: { viewModel.renameSelectedCollection($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        Button(role: .destructive) {
                            viewModel.deleteCollection(selected)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
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
        .onChange(of: viewModel.hasFilters) { _, hasFilters in
            if hasFilters { filtersExpanded = true }
        }
    }
}

