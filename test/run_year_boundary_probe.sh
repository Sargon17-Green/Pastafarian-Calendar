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

# Finite Chapel research checks use --fast and are explicitly non-acceptance.
printf '%s\n' 'YEAR_BOUNDARY_RESEARCH_BUILD_MODE=--fast_RESEARCH_ONLY_NOT_ACCEPTANCE'
timeout --signal=TERM --kill-after=5s 120s \
  chpl --fast -M src -M test test/year_boundary_probe.chpl \
  -o "$tmpdir/year_boundary_probe_research"
set +e
timeout --signal=TERM --kill-after=5s 120s \
  "$tmpdir/year_boundary_probe_research" --researchOnly=true \
  >"$tmpdir/research.log" 2>&1
research_rc=$?
set -e
cat "$tmpdir/research.log"
if [ "$research_rc" -ne 0 ] || ! grep -Fxq 'YEAR_BOUNDARY_RESEARCH_ONLY_RESULT=PASS' "$tmpdir/research.log"; then
  printf 'YEAR_BOUNDARY_RESEARCH_ONLY_EXIT=%s\n' "$research_rc"
  exit 1
fi

# Research diagnostics only: unchanged 240s watchdog and gate semantics.
# Record CPU versus wall time, plus cgroup throttling snapshots when available.
# Missing host metrics must not change the probe's exit code.
run_checked_timed() {
  local label="$1" output="$2" rc
  shift 2
  local TIMEFORMAT="YEAR_BOUNDARY_${label}_TIMING real=%R user=%U sys=%S cpu=%P"
  for metric in cpu.max cpu.stat memory.events; do
    if [[ -r "/sys/fs/cgroup/$metric" ]]; then
      printf 'YEAR_BOUNDARY_%s_BEFORE_%s\n' "$label" "$metric"
      cat "/sys/fs/cgroup/$metric" || true
    fi
  done
  { time timeout --signal=TERM --kill-after=5s 240s "$@" >"$output" 2>&1; } 2>"$output.timing"
  rc=$?
  cat "$output.timing" || true
  for metric in cpu.max cpu.stat memory.events; do
    if [[ -r "/sys/fs/cgroup/$metric" ]]; then
      printf 'YEAR_BOUNDARY_%s_AFTER_%s\n' "$label" "$metric"
      cat "/sys/fs/cgroup/$metric" || true
    fi
  done
  return "$rc"
}

# Checked structure/decomposition probe: one full year build, no duplicate API rebuild.
printf '%s\n' 'YEAR_BOUNDARY_STRUCTURE_BUILD_MODE=CHECKED'
timeout --signal=TERM --kill-after=5s 120s \
  chpl -M src -M test test/year_boundary_probe.chpl \
  -o "$tmpdir/year_boundary_structure_checked"
set +e
run_checked_timed STRUCTURE "$tmpdir/structure.log" \
  "$tmpdir/year_boundary_structure_checked" --structureOnly=true
structure_rc=$?
set -e
cat "$tmpdir/structure.log"
if [ "$structure_rc" -eq 0 ] && ! grep -Fxq 'YEAR_BOUNDARY_STRUCTURE_RESULT=PASS' "$tmpdir/structure.log"; then
  structure_rc=1
fi
printf 'YEAR_BOUNDARY_CHECKED_STRUCTURE_EXIT=%s\n' "$structure_rc"

# Checked public API probe in a separate bounded process, so it gets its own
# full build budget. It is compared against the independently decomposed
# first-day result emitted by the structure probe.
printf '%s\n' 'YEAR_BOUNDARY_API_BUILD_MODE=CHECKED'
timeout --signal=TERM --kill-after=5s 120s \
  chpl -M src -M test test/calendar_date_api_probe.chpl \
  -o "$tmpdir/calendar_date_api_checked"
set +e
run_checked_timed API "$tmpdir/api.log" "$tmpdir/calendar_date_api_checked"
api_rc=$?
set -e
cat "$tmpdir/api.log"
if [ "$api_rc" -eq 0 ] && ! grep -Fxq 'YEAR_BOUNDARY_CALENDAR_DATE_API_RESULT=PASS' "$tmpdir/api.log"; then
  api_rc=1
fi
printf 'YEAR_BOUNDARY_CHECKED_API_EXIT=%s\n' "$api_rc"

if [ "$structure_rc" -ne 0 ] || [ "$api_rc" -ne 0 ]; then
  printf '%s\n' 'YEAR_BOUNDARY_PROBE_RESULT=NOT_ACCEPTED'
  exit 1
fi

python3 test/compare_calendar_date_results.py "$tmpdir/structure.log" "$tmpdir/api.log"
printf '%s\n' 'YEAR_BOUNDARY_PROBE_RESULT=PASS'
