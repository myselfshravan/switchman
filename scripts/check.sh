#!/usr/bin/env bash
# Runs the same gates as CI: build, test with coverage gate, lint. Run before every commit.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build
swift test --enable-code-coverage
scripts/coverage.sh 90
swift format lint --strict --recursive Package.swift Sources Tests
