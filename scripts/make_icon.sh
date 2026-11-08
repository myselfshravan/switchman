#!/usr/bin/env bash
# Regenerates the placeholder Resources/AppIcon.icns.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p out
rm -rf out/AppIcon.iconset
swift scripts/make_icon.swift out/AppIcon.iconset
iconutil -c icns out/AppIcon.iconset -o Resources/AppIcon.icns
echo "Wrote Resources/AppIcon.icns"
