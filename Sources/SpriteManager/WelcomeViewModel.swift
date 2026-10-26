import AppKit
import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
    let controller: WelcomeWindowController
    let recentProjects: RecentProjectsStore

    init(controller: WelcomeWindowController, recentProjects: RecentProjectsStore) {
        self.controller = controller
        self.recentProjects = recentProjects
    }

    var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    func close() {
        controller.close()
    }

    func createProject() {
        controller.createProject()
    }

    func openExistingProject() {
        controller.openExistingProject()
    }

    func openProject(at url: URL) {
        controller.openProject(at: url)
    }
}
