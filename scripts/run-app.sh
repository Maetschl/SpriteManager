#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="$project_root/.build/arm64-apple-macosx/debug"
app_bundle="$project_root/.build/SpriteManager.app"

swift build --package-path "$project_root"

rm -rf "$app_bundle"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
cp "$build_root/SpriteManager" "$app_bundle/Contents/MacOS/SpriteManager"
cp "$project_root/Resources/Info.plist" "$app_bundle/Contents/Info.plist"
cp "$project_root/Resources/AppIcon.png" "$app_bundle/Contents/Resources/AppIcon.png"
cp "$project_root/Resources/AppIcon.icns" "$app_bundle/Contents/Resources/AppIcon.icns"
chmod +x "$app_bundle/Contents/MacOS/SpriteManager"

open "$app_bundle"
