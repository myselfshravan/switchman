#!/usr/bin/env bash
# Packs out/Switchman.app into out/Switchman-<version>.dmg with an Applications shortcut.
set -euo pipefail
cd "$(dirname "$0")/.."

version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' out/Switchman.app/Contents/Info.plist)"
staging=out/dmg
rm -rf "$staging"
mkdir -p "$staging"
cp -R out/Switchman.app "$staging/"
ln -s /Applications "$staging/Applications"
hdiutil create -volname Switchman -srcfolder "$staging" -ov -format UDZO "out/Switchman-$version.dmg"
rm -rf "$staging"
echo "Built out/Switchman-$version.dmg"
