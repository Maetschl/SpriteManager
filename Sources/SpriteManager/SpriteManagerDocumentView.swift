import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteManagerDocumentView: View {
    @StateObject private var viewModel: SpriteManagerDocumentViewModel

    init(document: ProjectDocument) {
        _viewModel = StateObject(wrappedValue: SpriteManagerDocumentViewModel(document: document))
    }

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeader(document: viewModel.document)
            Divider()
            TabView(selection: $viewModel.selectedTab) {
                SpritesWorkspace(document: viewModel.document, showingImporter: $viewModel.showingImporter)
                    .tabItem { Label("Sprites", systemImage: "square.grid.2x2") }
                    .tag(0)
                SheetsWorkspace(
                    document: viewModel.document,
                    onEditSprite: { spriteID in viewModel.selectSpriteForEditing(spriteID) },
                    requestedPlacementID: $viewModel.requestedPlacementID
                )
                    .tabItem { Label("Spritesheets", systemImage: "rectangle.3.group") }
                    .tag(1)
                PaletteWorkspace(document: viewModel.document)
                    .tabItem { Label("Color Pallete", systemImage: "paintpalette") }
                    .tag(2)
                QualityWorkspace(document: viewModel.document) { issue in
                    viewModel.openQualityIssue(issue)
                }
                    .tabItem { Label("Quality", systemImage: "checkmark.shield") }
                    .tag(3)
                PackPreviewWorkspace(document: viewModel.document)
                    .tabItem { Label("Pack Preview", systemImage: "rectangle.on.rectangle.angled") }
                    .tag(4)
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(AppPalette.window)
        .toolbar {
            ToolbarItemGroup {
                Button("Load Assets", systemImage: "square.and.arrow.down") { viewModel.showingImporter = true }
                Divider()
                Button("Undo", systemImage: "arrow.uturn.backward") { viewModel.undo() }
                    .disabled(!viewModel.canUndo)
                Button("Redo", systemImage: "arrow.uturn.forward") { viewModel.redo() }
                    .disabled(!viewModel.canRedo)
                Divider()
                Button("Save Changes", systemImage: "checkmark.circle.fill", action: viewModel.save)
                    .disabled(!viewModel.isDirty)
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingImporter,
            allowedContentTypes: [.png],
            allowsMultipleSelection: true
        ) { result in viewModel.importFiles(result) }
        .alert("SpriteManager", isPresented: Binding(
            get: { viewModel.hasError },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", action: viewModel.clearError)
        } message: {
            Text(viewModel.errorText)
        }
        .alert("Library conflict", isPresented: Binding(
            get: { viewModel.hasConflicts },
            set: { if !$0 { viewModel.resolveConflict(useProjectVersion: false) } }
        )) {
            Button("Use Project Version") {
                viewModel.resolveConflict(useProjectVersion: true)
            }
            Button("Keep Library Version", role: .cancel) {
                viewModel.resolveConflict(useProjectVersion: false)
            }
        } message: {
            Text(viewModel.conflictText)
        }
        .onChange(of: viewModel.projectName) { _, _ in viewModel.projectNameDidChange() }
        .overlay {
            WindowCloseGuard(document: viewModel.document)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
    }
}

struct QualityWorkspace: View {
    @ObservedObject var document: ProjectDocument
    let onSelectIssue: (QualityIssue) -> Void

    private var report: QualityReport { document.qualityReport() }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Label("Pack quality", systemImage: "checkmark.shield")
                    .font(.title3.weight(.semibold))
                Spacer()
                Label("\(report.errors.count) errors", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(report.errors.isEmpty ? Color.secondary : Color.red)
                Label("\(report.warnings.count) warnings", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(report.warnings.isEmpty ? Color.secondary : Color.orange)
            }
            .padding(18)
            Divider()
            if report.isClean {
                ContentUnavailableView(
                    "Pack looks ready",
                    systemImage: "checkmark.seal",
                    description: Text("No composition issues were found in the current project.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(report.issues) { issue in
                    Button {
                        onSelectIssue(issue)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(issue.severity == .error ? Color.red : Color.orange)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.message)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 8) {
                                    if let sheetID = issue.sheetID,
                                       let sheet = document.project.sheets.first(where: { $0.id == sheetID }) {
                                        Text(sheet.name)
                                    }
                                    if let spriteID = issue.spriteID,
                                       let asset = document.asset(for: spriteID) {
                                        Text(asset.name)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(AppPalette.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(AppPalette.muted)
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
        .background(AppPalette.canvas)
    }
}

@MainActor
final class PackPreviewWorkspaceViewModel: ObservableObject {
    let document: ProjectDocument
    @Published var configuration: PackPreviewConfiguration
    @Published var image: CGImage?

    init(document: ProjectDocument) {
        self.document = document
        self.configuration = document.project.previewConfiguration ?? PackPreviewConfiguration(title: document.project.name)
        self.image = nil
    }

    func refresh() {
        image = try? document.renderedPackPreview(configuration: configuration)
    }

    func update(_ configuration: PackPreviewConfiguration) {
        self.configuration = configuration
        document.updatePreviewConfiguration(configuration)
        refresh()
    }

    func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(safeName(document.project.name))-Preview.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try document.exportPackPreview(to: url, configuration: configuration)
        } catch {
            document.errorMessage = error.localizedDescription
        }
    }

    private func safeName(_ name: String) -> String {
        let value = name.replacingOccurrences(of: "[^A-Za-z0-9_-]+", with: "-", options: .regularExpression)
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

struct PackPreviewWorkspace: View {
    @ObservedObject var document: ProjectDocument
    @StateObject private var viewModel: PackPreviewWorkspaceViewModel

    init(document: ProjectDocument) {
        self.document = document
        _viewModel = StateObject(wrappedValue: PackPreviewWorkspaceViewModel(document: document))
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Pack preview", systemImage: "rectangle.on.rectangle.angled")
                        .font(.title3.weight(.semibold))
                    Text("Create one visual overview of the current project using its effective palette and sheet borders.")
                        .font(.callout)
                        .foregroundStyle(AppPalette.muted)
                    InspectorSection(title: "Presentation") {
                        TextField("Title", text: Binding(
                            get: { viewModel.configuration.title },
                            set: { value in
                                var configuration = viewModel.configuration
                                configuration.title = value
                                viewModel.update(configuration)
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        ColorPicker("Background", selection: Binding(
                            get: { viewModel.configuration.background.swiftColor },
                            set: { color in
                                let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .black
                                var configuration = viewModel.configuration
                                configuration.background = RGBAColor(
                                    r: Double(nsColor.redComponent),
                                    g: Double(nsColor.greenComponent),
                                    b: Double(nsColor.blueComponent),
                                    a: Double(nsColor.alphaComponent)
                                )
                                viewModel.update(configuration)
                            }
                        ))
                        Stepper("Spacing: \(viewModel.configuration.spacing) px", value: Binding(
                            get: { viewModel.configuration.spacing },
                            set: { value in
                                var configuration = viewModel.configuration
                                configuration.spacing = max(0, value)
                                viewModel.update(configuration)
                            }
                        ), in: 0...120)
                        Stepper("Scale: \(viewModel.configuration.scale)×", value: Binding(
                            get: { viewModel.configuration.scale },
                            set: { value in
                                var configuration = viewModel.configuration
                                configuration.scale = max(1, value)
                                viewModel.update(configuration)
                            }
                        ), in: 1...12)
                        Toggle("Show sheet names", isOn: Binding(
                            get: { viewModel.configuration.showsSheetNames },
                            set: { value in
                                var configuration = viewModel.configuration
                                configuration.showsSheetNames = value
                                viewModel.update(configuration)
                            }
                        ))
                        Toggle("Show palette", isOn: Binding(
                            get: { viewModel.configuration.showsPalette },
                            set: { value in
                                var configuration = viewModel.configuration
                                configuration.showsPalette = value
                                viewModel.update(configuration)
                            }
                        ))
                    }
                    Button("Export Pack Preview", systemImage: "square.and.arrow.up") {
                        viewModel.export()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(18)
            }
            .frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
            Divider()
            Group {
                if let image = viewModel.image {
                    ScrollView([.horizontal, .vertical]) {
                        Image(nsImage: NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .padding(30)
                    }
                } else {
                    ContentUnavailableView(
                        "No preview yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Add spritesheets to generate a pack overview.")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppPalette.canvas)
        }
        .onAppear { viewModel.refresh() }
        .onChange(of: document.project.sheets) { _, _ in viewModel.refresh() }
        .onChange(of: document.project.palette) { _, _ in viewModel.refresh() }
        .background(AppPalette.window)
    }
}

