#!/usr/bin/env bash
# Builds out/Switchman.app: universal (arm64 + x86_64) release build of the app and the CLI,
# wrapped in a bundle with Info.plist, icon and the Core resource bundle. Unsigned.
set -euo pipefail
cd "$(dirname "$0")/.."

archs=(--arch arm64 --arch x86_64)
swift build -c release "${archs[@]}" --product SwitchmanApp
swift build -c release "${archs[@]}" --product switchman
bin="$(swift build -c release "${archs[@]}" --show-bin-path)"
version="$("$bin/switchman" --version | awk '{ print $2 }')"

app=out/Switchman.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/SwitchmanApp" "$app/Contents/MacOS/Switchman"
# Not "switchman": the file system is case-insensitive and the app binary is "Switchman".
cp "$bin/switchman" "$app/Contents/MacOS/switchman-cli"
cp -R "$bin/Switchman_SwitchmanCore.bundle" "$app/Contents/Resources/"
cp Resources/AppIcon.icns "$app/Contents/Resources/"
sed "s/__VERSION__/$version/g" Resources/Info.plist > "$app/Contents/Info.plist"
plutil -lint "$app/Contents/Info.plist" > /dev/null
echo "Built $app ($version)"
