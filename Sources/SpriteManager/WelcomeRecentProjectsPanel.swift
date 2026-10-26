import SwiftUI

struct WelcomeRecentProjectsPanel: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Projects")
                .font(.system(size: 22, weight: .semibold))
                .padding(.horizontal, 28)
                .padding(.top, 30)
                .padding(.bottom, 18)
            if viewModel.recentProjects.projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("No Recent Projects")
                        .font(.headline)
                    Text("Projects you open will appear here.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            } else {
                List(selection: $viewModel.selectedURL) {
                    ForEach(viewModel.recentProjects.projects) { project in
                        RecentProjectRow(project: project)
                            .tag(project.url)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) { viewModel.openProject(at: project.url) }
                    }
                }
                .listStyle(.sidebar)
                .onSubmit {
                    if let selectedURL = viewModel.selectedURL {
                        viewModel.openProject(at: selectedURL)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).brightness(0.035))
    }
}
