#!/bin/sh
# For building on a Mac by hand: copy the web UI and catalog from the Android assets next to this
# project (CI does the equivalent from release assets).
#   sh ios/tools/fetch_resources.sh /path/to/collectify/android/app/src/main/assets
set -e
ASSETS="${1:?path to android/app/src/main/assets}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$HERE/Resources"
rm -rf "$HERE/Resources/www"
cp -R "$ASSETS/www" "$HERE/Resources/www"
cp "$ASSETS/collectify.db" "$HERE/Resources/collectify.db"
cp "$ASSETS/catalog_version.txt" "$HERE/Resources/catalog_version.txt"
echo "resources ready; now: cd ios && xcodegen generate && open Collectify.xcodeproj"
