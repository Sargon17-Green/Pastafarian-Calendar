#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage44-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH22_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE44_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE44_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage45Tests.kt \
  -include-runtime -d "$work/stage45.jar"
if ! kotlin -classpath "$work/stage45.jar" pastafari.Stage45Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH22_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE45_REAL_GATE_396_PAIRS_RANKED_GREEN \
  STAGE45_SYNTHETIC_128_CORRECTIONS_128_MATCH_GREEN \
  STAGE45_MANAGER_128_SESSIONS_GREEN \
  STAGE45_BIGINT_128_TRIPLES_256_CORRECTIONS_128_INVALID_RANK_REJECTS \
  STAGE45_YEAR_BOUNDS_AND_CLOSING_GATE_GREEN \
  STAGE45_GUARDS_REPLAY_METRICS_GREEN \
  STAGE45_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE45_FULL_NATIVE_GREEN
