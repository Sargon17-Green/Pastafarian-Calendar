#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage20-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_PATCH10_PREVIOUS_STAGES_FAILED >&2
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
  STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_PATCH10_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage21Tests.kt \
  src/test/kotlin/pastafari/Stage21BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage21.jar"; then
    echo E_PATCH10_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage21.jar" pastafari.Stage21Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH10_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE21_PATCHED_GREEN_720 \
  STAGE21_PRESERVED_LEGACY_RED_720 \
  STAGE21_PRESERVED_FIRST_WRITE_GREEN_720 \
  STAGE21_PRESERVED_WRONG_WRITES_3600 \
  STAGE21_ALL_SIX_SNAPSHOT_READS_GREEN_4320 \
  STAGE21_INPUT_GUARDS_AND_OWNERSHIP_PASS \
  STAGE21_46_IDENTITY_GREEN_LEGACY_RED \
  STAGE21_46_REVERSE_GREEN_LEGACY_RED \
  STAGE21_NATURAL_46_ORACLE_GREEN STAGE21_PRODUCTION_46_GREEN \
  STAGE21_BOOT_REPLAY_GUARDS_PASS STAGE21_CONTEXT_OWNERSHIP_PASS \
  STAGE21_EARLIER_ROUTES_PASS STAGE21_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH10_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage21.jar" pastafari.Stage21BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH10_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE21_BIGINT_CORRECTED_GREEN_4320 \
  STAGE21_BIGINT_PRESERVED_LEGACY_RED_4320 \
  STAGE21_BIGINT_PRESERVED_FIRST_GREEN_4320 \
  STAGE21_BIGINT_LEGACY_WRONG_WRITES_21600
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_PATCH10_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
printf '%s\n' STAGE21_FULL_NATIVE_GREEN
