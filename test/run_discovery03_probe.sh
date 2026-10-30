#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
chpl -M src -M test test/discovery03_probe.chpl -o "$tmpdir/discovery03_probe"
"$tmpdir/discovery03_probe"
