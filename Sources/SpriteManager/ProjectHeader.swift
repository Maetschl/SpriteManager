import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ProjectHeader: View {
    @ObservedObject var document: ProjectDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                TextField("Project name", text: Binding(
                    get: { document.project.name },
                    set: { document.updateProjectNameLive($0) }
                ), onEditingChanged: { editing in
                    if !editing { document.finishProjectNameEdit() }
                }, onCommit: {
                    document.finishProjectNameEdit()
                })
                .textFieldStyle(.plain)
                .font(.headline)
                Text("\(document.projectAssetCount) project sprites · \(document.project.sheets.count) sheets")
                    .font(.caption)
                    .foregroundStyle(AppPalette.muted)
            }
            Spacer()
            HStack(spacing: 7) {
                Circle()
                    .fill(document.isDirty ? .orange : .green)
                    .frame(width: 7, height: 7)
                Text(document.isDirty ? "Unsaved changes" : "Saved")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppPalette.muted)
            }
            .help(document.isDirty ? "Use Save Changes or cmd+s" : "Everything is saved")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

