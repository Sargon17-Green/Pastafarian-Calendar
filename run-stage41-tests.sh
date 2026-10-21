#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage40-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH20_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE40_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE40_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage41Tests.kt \
  -include-runtime -d "$work/stage41.jar"
if ! kotlin -classpath "$work/stage41.jar" pastafari.Stage41Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_PATCH20_TESTS_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE41_REAL_GATE_RANKING_GREEN_231 \
  STAGE41_SYNTHETIC_GREEN_64_PATCHED_64_MATCH \
  STAGE41_MANAGER_SESSIONS_GREEN_128 \
  STAGE41_BIGINT_GREEN_128_PAIRS_256_RANK_CORRECTIONS \
  STAGE41_YEAR_LENGTH_BOUNDARIES_GREEN \
  STAGE41_GUARDS_REPLAY_METRICS_GREEN \
  STAGE41_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/green.log"
done
printf '%s\n' STAGE41_FULL_NATIVE_GREEN
