import Foundation
import SwiftUI

@MainActor
final class ProjectHeaderViewModel: ObservableObject {
    let document: ProjectDocument

    init(document: ProjectDocument) {
        self.document = document
    }

    var projectName: String { document.project.name }
    var projectAssetCount: Int { document.projectAssetCount }
    var sheetCount: Int { document.project.sheets.count }
    var isDirty: Bool { document.isDirty }

    var projectNameBinding: Binding<String> {
        Binding(
            get: { [document] in document.project.name },
            set: { [document] value in document.updateProjectNameLive(value) }
        )
    }

    func finishProjectNameEdit() {
        document.finishProjectNameEdit()
    }
}
