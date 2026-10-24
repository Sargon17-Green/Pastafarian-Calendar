#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage50-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH25_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE50_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE50_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage51Tests.kt \
  -include-runtime -d "$work/stage51.jar"
if ! kotlin -classpath "$work/stage51.jar" pastafari.Stage51Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH25_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE51_REAL_231_GATE_PAIRS_ORACLE_GREEN \
 STAGE51_SYNTHETIC_64_WRAPS_FIXED_64_BACKWARD_MATCH_GREEN \
 STAGE51_BIGINT_128_WRAPS_FIXED_128_BACKWARD_MATCH_GREEN \
 STAGE51_GUARDS_REPLAY_METRICS_GREEN \
 STAGE51_PATCH_NATIVE_GREEN
do
 grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE51_FULL_NATIVE_GREEN
