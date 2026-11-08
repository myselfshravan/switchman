#!/usr/bin/env bash
# Fails if SwitchmanCore line coverage is below the threshold (default 90%).
# Expects `swift test --enable-code-coverage` to have run already.
set -euo pipefail
cd "$(dirname "$0")/.."

threshold="${1:-90}"
bin_path="$(swift build --show-bin-path)"
profile="$bin_path/codecov/default.profdata"
binary="$bin_path/SwitchmanPackageTests.xctest/Contents/MacOS/SwitchmanPackageTests"

report="$(xcrun llvm-cov report "$binary" -instr-profile "$profile" Sources/SwitchmanCore)"
echo "$report"
coverage="$(echo "$report" | awk '/^TOTAL/ { gsub("%", "", $10); print $10 }')"
echo "SwitchmanCore line coverage: ${coverage}% (minimum ${threshold}%)"
awk -v c="$coverage" -v t="$threshold" 'BEGIN { exit !(c >= t) }'
