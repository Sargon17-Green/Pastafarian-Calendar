#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
chpl -M src -M test test/year_boundary_probe.chpl -o "$tmpdir/year_boundary_probe"
"$tmpdir/year_boundary_probe"
