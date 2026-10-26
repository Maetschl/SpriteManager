#!/bin/zsh
set -euo pipefail

readonly expected_name="Maetschl"
readonly expected_email="maetschl@gmail.com"
readonly project_root="$(cd "$(dirname "$0")/.." && pwd)"
readonly info_plist="$project_root/Resources/Info.plist"

usage() {
    cat <<'EOF'
Usage: ./scripts/release.sh [--dry-run] <patch|minor|major>

Creates the next semantic version, commits the change, creates an annotated tag,
and pushes main plus the tag to origin.
EOF
}

fail() {
    print -u2 "release.sh: $1"
    exit 1
}

if (( $# == 0 )); then
    usage
    exit 1
fi

dry_run=false
if [[ "$1" == "--dry-run" ]]; then
    dry_run=true
    shift
fi

if (( $# != 1 )); then
    usage
    exit 1
fi

bump_type="$1"
if [[ "$bump_type" != "patch" && "$bump_type" != "minor" && "$bump_type" != "major" ]]; then
    fail "bump type must be patch, minor, or major"
fi

current_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$info_plist")"
if [[ ! "$current_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    fail "invalid current version: $current_version"
fi

version_parts=(${(s:.:)current_version})
major=$version_parts[1]
minor=$version_parts[2]
patch=$version_parts[3]

case "$bump_type" in
    patch)
        patch=$((patch + 1))
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
esac

next_version="$major.$minor.$patch"
tag="v$next_version"

if $dry_run; then
    print "$next_version"
    exit 0
fi

if [[ "$(git -C "$project_root" branch --show-current)" != "main" ]]; then
    fail "release must run from the main branch"
fi

if [[ -n "$(git -C "$project_root" status --porcelain)" ]]; then
    fail "worktree has uncommitted changes"
fi

actual_name="$(git -C "$project_root" config --local --get user.name || true)"
actual_email="$(git -C "$project_root" config --local --get user.email || true)"
if [[ "$actual_name" != "$expected_name" || "$actual_email" != "$expected_email" ]]; then
    fail "local Git identity must be $expected_name <$expected_email>"
fi

if git -C "$project_root" rev-parse --verify --quiet "refs/tags/$tag" >/dev/null; then
    fail "tag already exists locally: $tag"
fi

if git -C "$project_root" ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
    fail "tag already exists on origin: $tag"
fi

temporary_plist="$(mktemp)"
cp "$info_plist" "$temporary_plist"
trap 'rm -f "$temporary_plist"' EXIT

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $next_version" "$temporary_plist"
cp "$temporary_plist" "$info_plist"

git -C "$project_root" add Resources/Info.plist
git -C "$project_root" commit -m "Bump version to $next_version"
git -C "$project_root" tag -a "$tag" -m "SpriteManager $next_version"
git -C "$project_root" push origin main "$tag"

print "Released $tag"
