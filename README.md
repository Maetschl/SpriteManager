# SpriteManager

SpriteManager is a native macOS 14+ SwiftUI/AppKit application for managing pixel-art sprite libraries, portable `.pixproj` projects, spritesheets, and project-local color palettes.

## Features

- Global sprite library with stable UUIDs, PNG preservation, metadata, search, and `Unassigned` classification.
- Pixel-perfect sprite editing with integer-only shifting, clipping, transparency fill, undo, and redo.
- Multiple spritesheets per project with manual placement, duplication, integer coordinates, borders, and PNG/JSON export.
- Non-destructive project color palettes. Palette edits, aliases, previews, click-to-select, synchronized zoom/panning, and export rendering never modify source PNGs.
- Xcode-style Welcome window with native recent projects, Create/Open actions, `Window > Welcome to SpriteManager`, and `⇧⌘1`.
- Explicit saving through `Save Changes`, `File > Save`, or `⌘S`.

## Project structure

The source is intentionally split so each model, view, view model, store, document type, and utility has a focused file. Views compose controls and bindings; state transitions, filtering, rendering actions, import/export, and document coordination live in `*ViewModel` or model/store types.

The project uses Swift 6 language mode and Swift Testing. The native Xcode target includes every source file explicitly, including `Resources/AppIcon.icns`.

## Build and run

Open the native project and run the `SpriteManager` scheme with `⌘R`:

```sh
xed SpriteManager.xcodeproj
```

Or build and launch a standalone app bundle from the command line:

```sh
zsh scripts/run-app.sh
```

The command-line bundle is written to `.build/SpriteManager.app`. The native Xcode build produces the normal `.app` under DerivedData.

## Verify

```sh
swift build
swift test
xcodebuild -project SpriteManager.xcodeproj -scheme SpriteManager -configuration Debug -sdk macosx CODE_SIGNING_ALLOWED=NO build
```

The test suite covers persistence, migration, library sharing, pixel operations, palette remapping and aliases, export manifests, Welcome layout metrics, and document behavior.

## Storage formats

The global library is stored at `Application Support/SpriteManager/Library`. A `.pixproj` document is a portable package containing `project.json` and embedded PNG assets. Existing `.spritesproject` documents remain readable. Spritesheet export writes the final PNG and a JSON manifest containing placement, palette, border, and renderer metadata.

