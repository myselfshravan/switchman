#!/usr/bin/env bash
# Refreshes the vendored Public Suffix List. Dev-time only; the app never touches the network.
set -euo pipefail
cd "$(dirname "$0")/.."

curl -fsSL https://publicsuffix.org/list/public_suffix_list.dat \
    -o Sources/SwitchmanCore/Resources/public_suffix_list.dat
echo "Updated: $(grep -c '^[^/]' Sources/SwitchmanCore/Resources/public_suffix_list.dat) rules"
