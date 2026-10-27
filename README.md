# SpriteManager

SpriteManager is a native macOS workspace for turning a growing collection of pixel-art sprites into organized, consistent, ready-to-share packs.

It brings the parts of a sprite-pack workflow that are easy to lose across folders and image editors into one place: a reusable sprite library, hands-on spritesheet composition, project-local palette control, visual review, and export.

## What SpriteManager helps you do

### Keep a sprite library that stays useful

Import PNG sprites one by one and keep their identity, dimensions, pixels, and metadata together. Every asset receives a permanent UUID, can be searched from the library, and starts in `Unassigned` until it is ready to be used in a pack.

The same source sprite can be reused across multiple projects without creating disconnected copies. This makes it easier to revisit an existing asset, correct it once, and keep its uses consistent.

### Correct sprites without losing pixel control

The sprite editor is designed for precise cleanup rather than broad image editing. Shift the contents of a sprite by whole pixels, keep its original canvas size, clip pixels that leave the frame, and fill the exposed area with transparency.

Pixel-perfect zoom, an optional grid, undo, and redo make it practical to center sprites and correct small alignment issues before they reach a final sheet.

### Build and iterate on spritesheets

Create as many sheets as a project needs, configure each canvas, and place sprites manually with integer coordinates. Duplicate a sheet to create a variation while keeping the source sprites shared and the new composition independent.

Each sheet can preview a one-pixel non-destructive border effect. There is no scaling, rotation, or automatic packing in the current product, so the final arrangement remains intentional and easy to inspect.

### Keep a pack's colors consistent

Generate a project palette from the opaque colors actually used by the sprites in its sheets. Edit a palette color to preview a project-wide recolor, or remove a color and redirect it to the nearest surviving color.

Palette changes are non-destructive: source PNGs remain untouched and the effective colors are applied during sheet rendering and export. Synchronized previews, zoom and panning, pink color highlighting, and click-to-select make it easier to find where a color is used before changing it.

### Export a result you can work with

Export each spritesheet as a PNG together with a JSON manifest containing the source sprites, positions, dimensions, composition order, palette configuration, border settings, and renderer metadata. The result is suitable for packaging, review, and downstream use while preserving the information needed to understand how the sheet was made.

## A practical pack workflow

1. Import individual PNG sprites into the library.
2. Search, inspect, and make pixel-level alignment corrections.
3. Create a spritesheet for each group, variation, or deliverable.
4. Place sprites manually and duplicate sheets when a new composition is needed.
5. Generate or adjust the project palette and preview border treatments.
6. Review the original and updated renders, then export the final PNG and manifest.

## Who it is for

- Independent creators preparing commercial sprite packs.
- Pixel artists who need a reliable place to organize and refine assets.
- Creators who reuse the same sprites across several projects or pack variations.
- Small game-art workflows that benefit from deliberate composition and consistent color decisions.

## Welcome screen

![SpriteManager Welcome screen](docs/welcome-screen.png)

The Welcome screen provides quick access to recent projects and the actions to create or open a `.pixproj` project.

## Product direction

The next product improvements will focus on reducing repetitive pack-production work while keeping artists in control. Planned areas include:

- Richer tags, collections, and filtering for larger sprite libraries.
- Color variants and named versions of a sprite or pack.
- Batch operations for common cleanup and organization tasks.
- Export presets for different pack formats and delivery targets.
- Visual consistency checks for dimensions, alignment, palette use, and sheet composition.

These are planned product directions, not capabilities currently included in the application.

## Current boundaries

SpriteManager currently focuses on static pixel-art assets. It does not yet provide animation timelines, automatic packing, sprite scaling or rotation, or direct integrations with Godot, Unity, TexturePacker, or other game engines.

<details>
<summary>Technical reference</summary>

### Project format

Projects use the portable `.pixproj` package format. A project contains its project manifest and embedded PNG assets so it can be reopened on another Mac. Existing `.spritesproject` documents remain readable.

The global library is stored at `Application Support/SpriteManager/Library`. Shared source sprites keep their UUID across projects, while sheets, placements, palettes, and render settings belong to the project.

### Build and run

Open the native project and run the `SpriteManager` scheme with `⌘R`:

```sh
xed SpriteManager.xcodeproj
```

Or build and launch a standalone app bundle from the command line:

```sh
zsh scripts/run-app.sh
```

The command-line bundle is written to `.build/SpriteManager.app`. The native Xcode build produces the normal `.app` under DerivedData.

### Releases

The current application version is `0.1.0`. Releases use semantic versioning:

- `patch` increments the final number for small fixes and maintenance changes.
- `minor` increments the middle number for backward-compatible features.
- `major` increments the first number only when explicitly requested.

From a clean `main` worktree configured with the `Maetschl` Git identity, run one of:

```sh
./scripts/release.sh patch
./scripts/release.sh minor
./scripts/release.sh major
```

The script updates `Resources/Info.plist`, creates the commit and annotated tag, and pushes them to GitHub. The release workflow tests the project, builds a universal macOS application, creates a DMG, generates a SHA-256 checksum, and publishes a stable release at [GitHub Releases](https://github.com/Maetschl/SpriteManager/releases).

The initial DMG is not signed or notarized, so macOS may display a security warning when it is opened. The workflow has optional signing and notarization steps that can be enabled later with Apple Developer credentials stored as GitHub Actions secrets.

### Verify

```sh
swift build
swift test
zsh scripts/test-release.sh
xcodebuild -project SpriteManager.xcodeproj -scheme SpriteManager -configuration Debug -sdk macosx CODE_SIGNING_ALLOWED=NO build
```

The test suite covers persistence, migration, library sharing, pixel operations, palette remapping and aliases, export manifests, Welcome layout metrics, and document behavior.

### Source structure

The source is intentionally split so each model, view, view model, store, document type, and utility has a focused file. Views compose controls and bindings; state transitions, filtering, rendering actions, import/export, and document coordination live in `*ViewModel` or model/store types.

</details>
