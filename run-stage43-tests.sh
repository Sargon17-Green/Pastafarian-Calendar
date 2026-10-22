#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage42-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH21_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE42_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE42_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage43Tests.kt \
  -include-runtime -d "$work/stage43.jar"
if ! kotlin -classpath "$work/stage43.jar" pastafari.Stage43Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH21_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE43_REAL_231_GATE_PAIRS_RANKED_GREEN \
  STAGE43_SYNTHETIC_64_REVERSED_128_RANK_FIXED_64_SORTED_128_RANK_MATCH \
  STAGE43_MANAGER_128_SESSIONS_GREEN \
  STAGE43_BIGINT_128_TRIPLES_256_CORRECTIONS_128_MIDDLE_MATCH \
  STAGE43_GUARDS_REPLAY_METRICS_GREEN \
  STAGE43_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE43_FULL_NATIVE_GREEN
