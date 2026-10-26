import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WelcomeView: View {
    @StateObject private var viewModel: WelcomeViewModel
    @State private var selectedURL: URL?

    init(controller: WelcomeWindowController, recentProjects: RecentProjectsStore) {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel(controller: controller, recentProjects: recentProjects))
    }

    var body: some View {
        GeometryReader { proxy in
            let widths = WelcomeLayoutMetrics.panelWidths(for: proxy.size)

            HStack(spacing: 0) {
                leftPanel(height: proxy.size.height)
                    .frame(width: widths.left)
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                rightPanel
                    .frame(width: widths.right)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .alert("Unable to Open Project", isPresented: Binding(
            get: { viewModel.controller.errorMessage != nil },
            set: { if !$0 { viewModel.controller.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.controller.errorMessage = nil }
        } message: {
            Text(viewModel.controller.errorMessage ?? "The project could not be opened.")
        }
    }

    private func leftPanel(height: CGFloat) -> some View {
        let contentScale = min(1, height / (WelcomeLayoutMetrics.referenceBase * 2))

        return ZStack(alignment: .topLeading) {
            WindowDragArea()
                .background(Color(nsColor: .windowBackgroundColor))

            Button {
                viewModel.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.34))
                            .frame(width: 210 * contentScale, height: 210 * contentScale)
                            .blur(radius: 46 * contentScale)
                            .blendMode(.screen)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.28), Color.blue.opacity(0.08), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150 * contentScale
                                )
                            )
                            .frame(width: 300 * contentScale, height: 300 * contentScale)
                            .blur(radius: 6 * contentScale)
                            .blendMode(.screen)
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220 * contentScale, height: 220 * contentScale)
                            .shadow(color: .blue.opacity(0.65), radius: 28 * contentScale, x: 0, y: 18 * contentScale)
                    }
                    .frame(height: 300 * contentScale)

                    VStack(spacing: 3) {
                        Text("SpriteManager")
                            .font(.system(size: max(26, 42 * contentScale), weight: .bold, design: .rounded))
                        Text("Version \(viewModel.version)")
                            .font(.system(size: max(12, 16 * contentScale), weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    WelcomeActionButton(title: "Create New Project…", systemImage: "plus.square", scale: contentScale) {
                        viewModel.createProject()
                    }
                    WelcomeActionButton(title: "Open Existing Project…", systemImage: "folder", scale: contentScale) {
                        viewModel.openExistingProject()
                    }
                }
                .padding(.horizontal, 72 * contentScale)
                .padding(.bottom, 66 * contentScale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(true)
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Projects")
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
            }
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
                List(selection: $selectedURL) {
                    ForEach(viewModel.recentProjects.projects) { project in
                        RecentProjectRow(project: project)
                            .tag(project.url)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                viewModel.openProject(at: project.url)
                            }
                    }
                }
                .listStyle(.sidebar)
                .onSubmit {
                    if let selectedURL {
                        viewModel.openProject(at: selectedURL)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).brightness(0.035))
    }
}

