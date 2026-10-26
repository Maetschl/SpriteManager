import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ImportDropZone: View {
    @Binding var showingImporter: Bool
    @Binding var isTargeted: Bool
    let importURLs: ([URL]) -> Void

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: isTargeted ? "arrow.down.circle.fill" : "square.and.arrow.down")
                .font(.title3)
                .foregroundStyle(.tint)
            Text(isTargeted ? "Release to import" : "Drop PNGs here")
                .font(.subheadline.weight(.semibold))
            Text("or")
                .font(.caption)
                .foregroundStyle(AppPalette.muted)
            Button("Choose files…") { showingImporter = true }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            isTargeted ? Color.accentColor.opacity(0.14) : Color.accentColor.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [5]))
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                    guard let data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          url.pathExtension.lowercased() == "png" else { return }
                    Task { @MainActor in importURLs([url]) }
                }
            }
            return true
        }
    }
}

