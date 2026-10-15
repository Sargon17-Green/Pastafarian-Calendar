#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage28-tests.sh > "$build_dir/prior.log" 2>&1; then
  cat "$build_dir/prior.log" >&2
  echo E_PATCH14_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$build_dir/prior.log"
grep -Fxq STAGE28_STRICT_RED_CONFIRMED "$build_dir/prior.log"
grep -Fxq STAGE28_DISCOVERY_NATIVE_PASS "$build_dir/prior.log"
grep -Fxq STAGE27_FULL_NATIVE_GREEN "$build_dir/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage29Tests.kt \
  -include-runtime -d "$build_dir/stage29.jar"
if ! kotlin -classpath "$build_dir/stage29.jar" pastafari.Stage29Tests > "$build_dir/patch.log" 2>&1; then
  cat "$build_dir/patch.log" >&2
  echo E_PATCH14_TESTS_FAILED >&2
  exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE29_NATURAL_NEGATIVE_GATE_PATCH_GREEN_24 \
  STAGE29_PRESERVED_EXPERIMENTAL_SCAR_RED_24 \
  STAGE29_SYNTHETIC_922_PATCH_GREEN_WITH_HISTORICAL_RED \
  STAGE29_REJECTION_BOUNDARY_GREEN_8 \
  STAGE29_BIGINT_AND_INPUT_GUARDS_PASS \
  STAGE29_MANAGER_REPLAY_ROLLBACK_AND_METRICS_GREEN \
  STAGE29_PATCH_NATIVE_GREEN
do
  grep -Fxq "$marker" "$build_dir/patch.log"
done
printf '%s\n' STAGE29_FULL_NATIVE_GREEN
