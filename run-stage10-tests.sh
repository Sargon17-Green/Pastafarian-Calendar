#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage09-tests.sh > "$build_dir/stage09.log" 2>&1; then
    cat "$build_dir/stage09.log" >&2
    echo E_DISCOVERY05_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage09.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN
do
  grep -Fxq "$marker" "$build_dir/stage09.log" || {
    echo "E_DISCOVERY05_MISSING_PREVIOUS:$marker" >&2; exit 1;
  }
done
if ! kotlinc \
  src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyRemainderAdapter.kt \
  src/main/kotlin/pastafari/SavePatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyDayTagAdapter.kt \
  src/main/kotlin/pastafari/DayTagPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyDistanceAdapter.kt \
  src/main/kotlin/pastafari/DistancePatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyStoneBuilder.kt \
  src/main/kotlin/pastafari/StonePatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyHiddenDropAdapter.kt \
  src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt src/main/kotlin/pastafari/LegacyPriorAdapter.kt src/main/kotlin/pastafari/PriorPatchWrapper.kt src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage10Tests.kt \
  src/test/kotlin/pastafari/Stage10BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage10StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage10.jar"; then
    echo E_DISCOVERY05_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage10.jar" pastafari.Stage10Tests > "$build_dir/probes.log" 2>&1; then
    cat "$build_dir/probes.log" >&2
    echo E_DISCOVERY05_PROBES_FAILED >&2; exit 1
fi
cat "$build_dir/probes.log"
for marker in STAGE10_BACKWARD_STORAGE_PASS_7 STAGE10_PATCH04_ROWS_GREEN_230 \
  STAGE10_PRODUCTION_WRONG_K1_PASS STAGE10_K1_EXPECTED_RED STAGE10_K2_EXPECTED_RED \
  STAGE10_K4_MATCH STAGE10_K6_EXPECTED_RED STAGE10_K7_EXPECTED_RED \
  STAGE10_EXPECTED_RED_4 STAGE10_MATCH_1 STAGE10_BAD_ACCESS_GUARDS_PASS \
  STAGE10_CONTEXT_GUARDS_REPLAY_PASS STAGE10_EARLIER_ROUTES_PASS \
  STAGE10_COMPLETE_EXPECTED_RED
do
  grep -Fxq "$marker" "$build_dir/probes.log" || {
    echo "E_DISCOVERY05_MISSING_MARKER:$marker" >&2; exit 1;
  }
done
if ! kotlin -classpath "$build_dir/stage10.jar" pastafari.Stage10BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
  cat "$build_dir/bigint.log" >&2; echo E_DISCOVERY05_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
grep -Fxq STAGE10_BIGINT_INDEPENDENT_PASS_35 "$build_dir/bigint.log"
grep -Fxq STAGE10_BIGINT_PATCH04_STONES_GREEN_175 "$build_dir/bigint.log"
if kotlin -classpath "$build_dir/stage10.jar" pastafari.Stage10StrictRedTests > "$build_dir/strict.log" 2>&1; then
  echo E_DISCOVERY05_STRICT_UNEXPECTED_GREEN >&2;exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE10_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
 echo E_DISCOVERY05_STRICT_FAILURE_UNRELATED >&2;exit 1
}
printf '%s\n' STAGE10_STRICT_RED_CONFIRMED STAGE10_NATIVE_EXPECTED_RED_COMPLETE
