#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage18-tests.sh > "$build_dir/previous.log" 2>&1; then
    cat "$build_dir/previous.log" >&2
    echo E_PATCH09_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/previous.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
  STAGE12_NATIVE_EXPECTED_RED_COMPLETE STAGE13_NATIVE_GREEN \
  STAGE14_NATIVE_EXPECTED_RED_COMPLETE STAGE15_FULL_NATIVE_GREEN \
  STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE17_FULL_NATIVE_GREEN \
  STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/previous.log" || {
        echo "E_PATCH09_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage19Tests.kt \
  src/test/kotlin/pastafari/Stage19BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage19.jar"; then
    echo E_PATCH09_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage19.jar" pastafari.Stage19Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH09_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE19_SINGLE_CORRECTED_GREEN_720 \
  STAGE19_SINGLE_LEGACY_RED_714 STAGE19_SINGLE_INCIDENTAL_MATCH_6 \
  STAGE19_SINGLE_LEGACY_WRONG_CELLS_1800 \
  STAGE19_REVERSED_SOURCE_CORRECTION_PASS STAGE19_INPUT_GUARDS_PASS \
  STAGE19_46_REVERSED_GREEN_AND_LEGACY_RED \
  STAGE19_46_IDENTITY_BOTH_GREEN STAGE19_46_SNAPSHOT_OWNERSHIP_PASS \
  STAGE19_NATURAL_46_ORACLE_GREEN STAGE19_NATURAL_46_LEGACY_RED \
  STAGE19_PRODUCTION_46_GREEN STAGE19_BOOT_REPLAY_GUARDS_PASS \
  STAGE19_CONTEXT_OWNERSHIP_PASS STAGE19_EARLIER_ROUTES_PASS \
  STAGE19_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH09_TEST_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage19.jar" pastafari.Stage19BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH09_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE19_BIGINT_CORRECTED_GREEN_4320 \
  STAGE19_BIGINT_PRESERVED_LEGACY_RED_4284 \
  STAGE19_BIGINT_PRESERVED_INCIDENTAL_MATCH_36 \
  STAGE19_BIGINT_LEGACY_WRONG_CELLS_10800
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_PATCH09_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
printf '%s\n' STAGE19_FULL_NATIVE_GREEN
