#!/usr/bin/env bash
# Runs the same gates as CI: build, test, lint. Run before every commit.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build
swift test
swift format lint --strict --recursive Package.swift Sources Tests
