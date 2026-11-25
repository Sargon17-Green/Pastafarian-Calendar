#!/usr/bin/env bash
# Stage03 PATCH01: normative SAVE implementation and exact-source Native QA.
set -uo pipefail

mkdir -p evidence build || exit $?
LOG="evidence/stage03-native-fpc.log"
: > "$LOG"
overall=0

run_step() {
  local label="$1"
  shift
  "$@" >>"$LOG" 2>&1
  local status=$?
  printf 'STAGE03_%s_EXIT=%s\n' "$label" "$status" | tee -a "$LOG"
  if [ "$status" -ne 0 ]; then
    overall=1
  fi
}

{
  echo "PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE"
  echo "SOURCE_SHA=$(git rev-parse HEAD)"
  echo "UTC_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >>"$LOG"

run_step FPC_VERSION_CHECK bash -c 'version="$(fpc -iV)" && echo "FPC_VERSION=$version" && test "$version" = "3.2.2"'
run_step ORACLE_SELF_TEST python3 docs/stage03_save_oracle.py --self-test
run_step ORACLE_EMIT python3 docs/stage03_save_oracle.py --emit build/stage03_save_vectors.tsv
run_step ORACLE_CHECK python3 docs/stage03_save_oracle.py --check build/stage03_save_vectors.tsv
run_step TSV_SHA256_CHECK bash -c 'digest="$(sha256sum build/stage03_save_vectors.tsv | cut -d" " -f1)" && echo "STAGE03_TSV_SHA256=$digest" && test "$digest" = "f011be78e4e6fe8489f8ae4f1e5040c0c161e6376db8b4d7c38e15d86b5b0017"'
run_step NATIVE_COMPILE bash -c 'cd test && fpc -B -Fu../src -FE../build stage03_save_regression.pas'
run_step NATIVE_SUITE build/stage03_save_regression build/stage03_save_vectors.tsv

for marker in \
  "STAGE03_CASES=128" \
  "STAGE03_EXPECTED_RED_COUNT=17" \
  "STAGE03_MATCH_COUNT=111" \
  "STAGE03_CHECKS_PASSED=1541" \
  "STAGE03_CHECKS_FAILED=0" \
  "STAGE03_RESULT=PASS"; do
  if ! grep -Fxq "$marker" "$LOG"; then
    echo "STAGE03_MARKER_MISSING=$marker" | tee -a "$LOG"
    overall=1
  fi
done

echo "STAGE03_EXIT=$overall" | tee -a "$LOG"
exit "$overall"
