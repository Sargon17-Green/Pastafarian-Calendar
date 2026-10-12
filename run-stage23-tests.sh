#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage22-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_PATCH11_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/prev.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
  STAGE12_NATIVE_EXPECTED_RED_COMPLETE STAGE13_NATIVE_GREEN \
  STAGE14_NATIVE_EXPECTED_RED_COMPLETE STAGE15_FULL_NATIVE_GREEN \
  STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE17_FULL_NATIVE_GREEN \
  STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE19_FULL_NATIVE_GREEN \
  STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE21_FULL_NATIVE_GREEN \
  STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_PATCH11_PREVIOUS_MARKER_MISSING:$marker" >&2
        exit 1
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
  src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyPriorAdapter.kt \
  src/main/kotlin/pastafari/PriorPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt \
  src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt \
  src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt \
  src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt \
  src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt \
  src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt src/main/kotlin/pastafari/PositionalNeighborPatchWrapper.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage23Tests.kt \
  src/test/kotlin/pastafari/Stage23BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage23.jar"; then
    echo E_PATCH11_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage23.jar" pastafari.Stage23Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH11_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE23_PATCHED_FINAL_GREEN_720 \
 STAGE23_PRESERVED_LEGACY_RED_720 STAGE23_FIRST_STIR_BOTH_GREEN_720 \
 STAGE23_STIR2_FRESH_SUM_GREEN_720 \
 STAGE23_INDEPENDENT_STIR_STEPS_8640 \
 STAGE23_SIGNED_AND_HUGE_INPUTS_GREEN STAGE23_INPUT_GUARDS_PASS \
 STAGE23_PRODUCTION_12_FRESH_STIRS_GREEN \
 STAGE23_BOOT_REPLAY_GUARDS_PASS STAGE23_CONTEXT_OWNERSHIP_PASS \
 STAGE23_EARLIER_ROUTES_PASS STAGE23_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH11_MISSING_MARKER:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage23.jar" pastafari.Stage23BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH11_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE23_BIGINT_FINAL_GREEN_4320 \
 STAGE23_BIGINT_PRESERVED_LEGACY_RED_4320 \
 STAGE23_BIGINT_FIRST_BOTH_GREEN_4320 \
 STAGE23_BIGINT_SECOND_FRESH_GREEN_4320 \
 STAGE23_BIGINT_INDEPENDENT_STEPS_51840
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_PATCH11_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
printf '%s\n' STAGE23_FULL_NATIVE_GREEN
