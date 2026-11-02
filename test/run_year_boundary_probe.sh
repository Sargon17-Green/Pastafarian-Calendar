#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
python3 test/weaving_reachability_oracle.py
python3 test/weaving_small_exact_oracle.py
python3 test/weaving_prefix_transfer.py
chpl -M src -M test test/year_boundary_probe.chpl -o "$tmpdir/year_boundary_probe"
# Timeout means inconclusive, not PASS.
if timeout --signal=TERM --kill-after=5s 180s "$tmpdir/year_boundary_probe"; then
  exit 0
else
  rc=$?
  if [ "$rc" -eq 124 ]; then
    printf '%s\n' 'YEAR_BOUNDARY_PROBE_RESULT=INCONCLUSIVE_TIMEOUT_180S'
  fi
  exit "$rc"
fi
