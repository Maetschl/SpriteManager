import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PaletteGrid: View {
    @ObservedObject var document: ProjectDocument
    @Binding var selectedColorID: UUID?
    let onSelectColor: (UUID) -> Void
    @State private var showingRegenerateConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label("Color Pallete", systemImage: "paintpalette")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let palette = document.effectivePalette {
                    Text("\(palette.colors.count) colors")
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                    Button("Regenerate", systemImage: "arrow.clockwise") {
                        showingRegenerateConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            Divider()

            if let palette = document.effectivePalette {
                if palette.colors.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(.tint)
                        Text("No opaque colors found")
                            .font(.title3.weight(.semibold))
                        Text("Add sprites to a spritesheet and regenerate the palette.")
                            .font(.callout)
                            .foregroundStyle(AppPalette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                                ForEach(palette.colors) { color in
                                    Button {
                                        onSelectColor(color.id)
                                    } label: {
                                        PaletteColorCard(color: color, isSelected: selectedColorID == color.id)
                                    }
                                    .buttonStyle(.plain)
                                    .id(color.id)
                                }
                            }
                            .padding(20)
                        }
                        .onChange(of: selectedColorID) { _, colorID in
                            guard let colorID else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(colorID, anchor: .center)
                            }
                        }
                    }
                    .background(AppPalette.canvas)
                }
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.tint)
                    Text("Create your project palette")
                        .font(.title3.weight(.semibold))
                    Text("Collect opaque colors from every sprite used by this project's spritesheets.")
                        .font(.callout)
                        .foregroundStyle(AppPalette.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                    Button("Create Palette", systemImage: "plus") {
                        document.createPalette()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .background(AppPalette.canvas)
        .confirmationDialog("Regenerate palette?", isPresented: $showingRegenerateConfirmation, titleVisibility: .visible) {
            Button("Regenerate", role: .destructive) {
                document.regeneratePalette()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This rebuilds the palette from the current sprites and discards pending color edits and deletions.")
        }
    }
}

