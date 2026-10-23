#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage46-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH23_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE46_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE46_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage47Tests.kt \
  -include-runtime -d "$work/stage47.jar"
if ! kotlin -classpath "$work/stage47.jar" pastafari.Stage47Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH23_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE47_REAL_GATE_231_PAIRS_GREEN \
  STAGE47_SYNTHETIC_64_CORRECTIONS_64_MATCH_GREEN \
  STAGE47_MANAGER_128_SESSIONS_GREEN \
  STAGE47_BIGINT_128_TRIPLES_256_CORRECTIONS_128_MATCH_128_EXTRA_REJECTS \
  STAGE47_GUARDS_REPLAY_METRICS_GREEN \
  STAGE47_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE47_FULL_NATIVE_GREEN
