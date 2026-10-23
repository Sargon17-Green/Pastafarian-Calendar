#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage48-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_PATCH24_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE48_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE48_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage49Tests.kt \
  -include-runtime -d "$work/stage49.jar"
if ! kotlin -classpath "$work/stage49.jar" pastafari.Stage49Tests > "$work/result.log" 2>&1; then
  cat "$work/result.log" >&2
  echo E_PATCH24_TESTS_FAILED >&2
  exit 1
fi
cat "$work/result.log"
for marker in STAGE49_REAL_GATE_231_PAIRS_CANONICAL_RANK_GREEN \
  STAGE49_SYNTHETIC_64_CORRECTIONS_64_ACCEPTED_MATCH_GREEN \
  STAGE49_MANAGER_128_SESSIONS_GREEN \
  STAGE49_BIGINT_128_CORRECTIONS_128_MATCH_GREEN \
  STAGE49_GUARDS_REPLAY_METRICS_GREEN \
  STAGE49_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$work/result.log"
done
printf '%s\n' STAGE49_FULL_NATIVE_GREEN
