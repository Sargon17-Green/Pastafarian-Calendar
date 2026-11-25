#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
python3 test/weaving_reachability_oracle.py
python3 test/weaving_small_exact_oracle.py
python3 test/weaving_prefix_transfer.py
python3 test/weaving_prefix_batch.py
python3 test/weaving_incremental_states.py
python3 test/weaving_extreme_ranks.py
timeout --signal=TERM --kill-after=5s 30s python3 test/weaving_dual_adjoint.py
timeout --signal=TERM --kill-after=5s 30s python3 test/weaving_sparse_dual.py
timeout --signal=TERM --kill-after=5s 30s python3 test/weaving_sparse_kernel_differential.py
# Diagnostic only: bounded actual median decisions, not full-year acceptance.
timeout --signal=TERM --kill-after=5s 65s python3 -u test/weaving_sparse_median_profile.py
# Keep the checked build as the sole Stage 6 gate.
chpl -M src -M test test/year_boundary_probe.chpl -o "$tmpdir/year_boundary_probe_checked"
if timeout --signal=TERM --kill-after=5s 180s "$tmpdir/year_boundary_probe_checked"; then
  exit 0
else
  rc=$?
  if [ "$rc" -ne 124 ]; then
    exit "$rc"
  fi
  printf '%s\n' 'YEAR_BOUNDARY_PROBE_RESULT=INCONCLUSIVE_TIMEOUT_180S'
fi

# A checked-build timeout is not a mathematical failure. Run the exact same
# source under the --fast mode already used by the separate Native rank probe,
# strictly as a diagnostic. This result can never turn the checked gate green.
printf '%s\n' 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_MODE=--fast_RESEARCH_ONLY_NOT_ACCEPTANCE'
set +e
timeout --signal=TERM --kill-after=5s 150s chpl --fast -M src -M test \
  test/year_boundary_probe.chpl -o "$tmpdir/year_boundary_probe_fast" \
  >"$tmpdir/fast-compile.log" 2>&1
compile_rc=$?
set -e
cat "$tmpdir/fast-compile.log"
if [ "$compile_rc" -ne 0 ]; then
  printf 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_COMPILE_EXIT=%s\n' "$compile_rc"
  exit 124
fi

set +e
timeout --signal=TERM --kill-after=5s 150s "$tmpdir/year_boundary_probe_fast" \
  >"$tmpdir/fast-run.log" 2>&1
fast_rc=$?
set -e
sed \
  -e 's/^YEAR_BOUNDARY_PROBE_RESULT=PASS$/YEAR_BOUNDARY_FAST_DIAGNOSTIC_PROBE_RESULT=PASS_RESEARCH_ONLY/' \
  "$tmpdir/fast-run.log" >"$tmpdir/fast-run-rendered.log"
cat "$tmpdir/fast-run-rendered.log"
if [ "$fast_rc" -eq 0 ]; then
  if grep -Fxq 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_PROBE_RESULT=PASS_RESEARCH_ONLY' \
      "$tmpdir/fast-run-rendered.log"; then
    printf '%s\n' 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_RESULT=PASS_RESEARCH_ONLY'
  else
    printf '%s\n' 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_RESULT=MISSING_PASS_MARKER'
  fi
elif [ "$fast_rc" -eq 124 ]; then
  printf '%s\n' 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_RESULT=INCONCLUSIVE_TIMEOUT_150S'
else
  printf 'YEAR_BOUNDARY_FAST_DIAGNOSTIC_EXIT=%s\n' "$fast_rc"
fi

# Preserve the checked-build timeout as the overall failure/inconclusive status.
exit 124
