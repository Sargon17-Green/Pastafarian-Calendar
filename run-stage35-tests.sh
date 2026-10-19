#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage34-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH17_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE34_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE34_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage35Tests.kt \
  -include-runtime -d "$work/stage35.jar"
if ! kotlin -classpath "$work/stage35.jar" pastafari.Stage35Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH17_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE35_REAL_GATE_GREEN_450_SESSIONS_150 \
  STAGE35_SYNTHETIC_GREEN_150_LEGACY_RED_12_MATCH_138 \
  STAGE35_BIGINT_GREEN_1024_LEGACY_RED_512 \
  STAGE35_YEAR5000_BOUNDS_AND_ORACLE_GREEN \
  STAGE35_GUARDS_REPLAY_METRICS_GREEN \
  STAGE35_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE35_FULL_NATIVE_GREEN
