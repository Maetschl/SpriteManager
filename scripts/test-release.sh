#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
release_script="$project_root/scripts/release.sh"
current_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$project_root/Resources/Info.plist")"

expect_version() {
    local bump_type="$1"
    local expected="$2"
    local actual="$("$release_script" --dry-run "$bump_type")"
    if [[ "$actual" != "$expected" ]]; then
        print -u2 "Expected $bump_type from $current_version to produce $expected, got $actual"
        exit 1
    fi
}

expect_version patch "0.1.1"
expect_version minor "0.2.0"
expect_version major "1.0.0"

if "$release_script" --dry-run invalid >/dev/null 2>&1; then
    print -u2 "Invalid bump type was accepted"
    exit 1
fi

print "Release script checks passed"
