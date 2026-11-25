#!/usr/bin/env bash
# Native differential and Discovery01 expected-RED gate. Run from repository root.
set -u -o pipefail
mkdir -p evidence build || exit $?

run_step() {
  local label="$1" status=0
  shift
  "$@" || status=$?
  printf 'STAGE02_%s_EXIT=%s\n' "$label" "$status"
  return "$status"
}

compile_suite() (
  cd test || exit $?
  fpc -B -Fu../src -FE../build "$1.pas"
)

run_suite() {
  local label="$1" binary="$2"
  run_step "$label"_COMPILE compile_suite "$binary" || return $?
  run_step "$label"_SUITE "./build/$binary" build/stage02_workcounts_vectors.tsv
}

run_discovery01_suite() {
  run_step "DISCOVERY01_COMPILE" compile_suite stage02_discovery01_remainder_save || return $?
  run_step "DISCOVERY01_SUITE" ./build/stage02_discovery01_remainder_save build/stage02_discovery01_vectors.tsv
}

(
  set -euo pipefail
  echo "PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE"
  echo "SOURCE_SHA=$(git rev-parse HEAD)"
  echo "UTC_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "FPC_VERSION=$(fpc -iV)"
  test "$(fpc -iV)" = "3.2.2"

  python3 docs/stage02_workcounts_oracle.py --self-test
  python3 docs/stage02_workcounts_oracle.py --emit build/stage02_workcounts_vectors.tsv
  python3 docs/stage02_workcounts_oracle.py --check build/stage02_workcounts_vectors.tsv
  digest="$(sha256sum build/stage02_workcounts_vectors.tsv | cut -d' ' -f1)"
  echo "STAGE02_TSV_SHA256=$digest"
  test "$digest" = "1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12"

  python3 docs/stage02_discovery01_oracle.py --self-test
  python3 docs/stage02_discovery01_oracle.py --emit build/stage02_discovery01_vectors.tsv
  python3 docs/stage02_discovery01_oracle.py --check build/stage02_discovery01_vectors.tsv
  discovery_digest="$(sha256sum build/stage02_discovery01_vectors.tsv | cut -d' ' -f1)"
  echo "STAGE02_DISCOVERY01_TSV_SHA256=$discovery_digest"
  test "$discovery_digest" = "1434ebaab9a2f3bc92e74f11192b99e1ce53e4cad39ceacea767a0f1583b9fed"

  run_suite WORKCOUNTS stage02_workcounts_regression
  run_suite CONTEXT stage02_context_integration
  run_suite LIFECYCLE stage02_lifecycle_boundaries
  run_discovery01_suite
) 2>&1 | tee evidence/stage02-native-fpc.log

status=$?
if [ "$status" -eq 0 ]; then
  for marker in \
    "DISCOVERY01_LEGACY_PATH=BigRegularModPositive" \
    "DISCOVERY01_CASES=4" \
    "DISCOVERY01_EXPECTED_RED_COUNT=3" \
    "DISCOVERY01_MATCH_COUNT=1" \
    "DISCOVERY01_CHECKS_PASSED=41" \
    "DISCOVERY01_CHECKS_FAILED=0" \
    "DISCOVERY01_RESULT=EXPECTED_RED_CONFIRMED"; do
    if ! grep -Fxq "$marker" evidence/stage02-native-fpc.log; then
      echo "STAGE02_DISCOVERY01_MARKER_MISSING=$marker" | tee -a evidence/stage02-native-fpc.log
      status=1
    fi
  done
fi

echo "STAGE02_EXIT=$status" | tee -a evidence/stage02-native-fpc.log
exit "$status"
