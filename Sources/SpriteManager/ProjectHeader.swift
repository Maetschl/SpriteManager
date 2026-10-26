import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ProjectHeader: View {
    @ObservedObject var document: ProjectDocument
    @StateObject private var viewModel: ProjectHeaderViewModel

    init(document: ProjectDocument) {
        self.document = document
        _viewModel = StateObject(wrappedValue: ProjectHeaderViewModel(document: document))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                TextField("Project name", text: viewModel.projectNameBinding, onEditingChanged: { editing in
                    if !editing { viewModel.finishProjectNameEdit() }
                }, onCommit: {
                    viewModel.finishProjectNameEdit()
                })
                .textFieldStyle(.plain)
                .font(.headline)
                Text("\(viewModel.projectAssetCount) project sprites · \(viewModel.sheetCount) sheets")
                    .font(.caption)
                    .foregroundStyle(AppPalette.muted)
            }
            Spacer()
            HStack(spacing: 7) {
                Circle()
                    .fill(viewModel.isDirty ? .orange : .green)
                    .frame(width: 7, height: 7)
                Text(viewModel.isDirty ? "Unsaved changes" : "Saved")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppPalette.muted)
            }
            .help(viewModel.isDirty ? "Use Save Changes or cmd+s" : "Everything is saved")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

