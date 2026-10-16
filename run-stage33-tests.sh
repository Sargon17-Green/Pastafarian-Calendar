#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage32-tests.sh > "$build_dir/prior.log" 2>&1; then
  cat "$build_dir/prior.log" >&2
  echo E_PATCH16_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$build_dir/prior.log"
grep -Fxq STAGE32_STRICT_RED_CONFIRMED "$build_dir/prior.log"
grep -Fxq STAGE32_DISCOVERY_NATIVE_PASS "$build_dir/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage33Tests.kt \
  -include-runtime -d "$build_dir/stage33.jar"
if ! kotlin -classpath "$build_dir/stage33.jar" pastafari.Stage33Tests > "$build_dir/result.log" 2>&1; then
  cat "$build_dir/result.log" >&2
  echo E_PATCH16_TESTS_FAILED >&2
  exit 1
fi
cat "$build_dir/result.log"
for marker in STAGE33_REAL_GATE_GREEN_656 \
  STAGE33_PRESERVED_EXPERIMENTAL_RED_41_MATCH_615 \
  STAGE33_PRODUCTION_SESSION_GREEN_164 \
  STAGE33_BIGINT_GREEN_1536_RED_384 \
  STAGE33_YEAR5000_LENGTH_BOUNDARIES_GREEN \
  STAGE33_GUARDS_REPLAY_METRICS_GREEN \
  STAGE33_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$build_dir/result.log"
done
printf '%s\n' STAGE33_FULL_NATIVE_GREEN
