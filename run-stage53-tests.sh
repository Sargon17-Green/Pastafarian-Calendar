#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage52-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH26_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE52_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE52_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage53Tests.kt \
  -include-runtime -d "$work/stage53.jar"
if ! kotlin -classpath "$work/stage53.jar" pastafari.Stage53Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH26_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE53_REAL_231_GATE_PAIRS_ORACLE_GREEN \
  STAGE53_SYNTHETIC_64_BOUNDARIES_CORRECTED_64_CONTROLS_GREEN \
  STAGE53_BIGINT_128_BOUNDARIES_CORRECTED_128_CONTROLS_GREEN \
  STAGE53_GUARDS_REPLAY_METRICS_GREEN \
  STAGE53_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE53_FULL_NATIVE_GREEN
