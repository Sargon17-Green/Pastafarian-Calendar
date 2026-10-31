#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
chpl -M src -M test test/bounded_composition_cache_probe.chpl -o "$tmpdir/bounded_composition_cache_probe"
"$tmpdir/bounded_composition_cache_probe"
