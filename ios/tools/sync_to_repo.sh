#!/bin/sh
# Copies the iOS sources + workflow into the releases repo working copy (the repo the CI builds from).
#   sh ios/tools/sync_to_repo.sh /path/to/collectify-app-releases
set -e
DEST="${1:?path to the collectify-app-releases checkout}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$DEST/ios" "$DEST/.github/workflows"
cp "$SRC/ci/ios.yml" "$DEST/.github/workflows/ios.yml"
rm -rf "$DEST/ios/App" "$DEST/ios/CollectifyCore" "$DEST/ios/tools"
cp -R "$SRC/App" "$SRC/CollectifyCore" "$SRC/tools" "$SRC/project.yml" "$SRC/.gitignore" "$DEST/ios/"
mkdir -p "$DEST/ios/Resources" && cp -R "$SRC/Resources/Assets.xcassets" "$DEST/ios/Resources/"
rm -rf "$DEST/ios/CollectifyCore/.build"
echo "synced to $DEST"
