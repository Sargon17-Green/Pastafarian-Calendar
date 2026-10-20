#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage38-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH19_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE38_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE38_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage39Tests.kt \
  -include-runtime -d "$work/stage39.jar"
if ! kotlin -classpath "$work/stage39.jar" pastafari.Stage39Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH19_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE39_REAL_GATE_GREEN_450_SESSIONS_150 \
  STAGE39_REAL_LEGACY_EXPECTED_RED_150 \
  STAGE39_SYNTHETIC_GREEN_150_LEGACY_RED_18_MATCH_132 \
  STAGE39_BIGINT_GREEN_1024_LEGACY_RED_256 \
  STAGE39_YEAR5000_BOUNDS_AND_ORACLE_GREEN \
  STAGE39_GUARDS_REPLAY_METRICS_GREEN \
  STAGE39_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE39_FULL_NATIVE_GREEN
