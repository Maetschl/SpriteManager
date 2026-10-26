import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteInspector: View {
    @ObservedObject var document: ProjectDocument

    var body: some View {
        ScrollView {
            if let asset = document.selectedAsset {
                VStack(alignment: .leading, spacing: 18) {
                    InspectorSection(title: "Sprite") {
                        TextField("Name", text: Binding(
                            get: { document.asset(for: asset.id)?.name ?? asset.name },
                            set: { document.updateAssetName(asset.id, name: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        LabeledContent("Category", value: asset.category.displayName)
                        LabeledContent("Dimensions", value: "\(asset.width) × \(asset.height) px")
                        LabeledContent("Source file", value: asset.originalFileName)
                        if document.assets[asset.id] == nil {
                            Button("Include in project", systemImage: "plus.circle.fill") {
                                document.includeAssetInProject(asset.id)
                            }
                            .buttonStyle(.borderedProminent)
                            Text("This asset is in the global library. Include it to package it with this project.")
                                .font(.caption)
                                .foregroundStyle(AppPalette.muted)
                        }
                    }
                    InspectorSection(title: "Stable identity") {
                        HStack(alignment: .top, spacing: 8) {
                            Text(asset.id.uuidString)
                                .font(.caption2.monospaced())
                                .textSelection(.enabled)
                                .lineLimit(2)
                            Spacer(minLength: 4)
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(asset.id.uuidString, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .help("Copy UUID")
                        }
                    }
                    InspectorSection(title: "Pixel editing") {
                        Label("Drag the image to shift its pixels.", systemImage: "hand.draw")
                        Text("The frame stays \(asset.width) × \(asset.height) px. Pixels leaving the frame are clipped and transparent pixels fill the exposed area.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.muted)
                    }
                }
                .padding(16)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Select a sprite")
                        .font(.headline)
                    Text("Its properties and editing guidance will appear here.")
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
        }
        .background(.regularMaterial)
    }
}

