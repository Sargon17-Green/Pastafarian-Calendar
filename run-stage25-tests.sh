#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage24-tests.sh > "$build_dir/previous.log" 2>&1; then
    cat "$build_dir/previous.log" >&2
    echo E_PATCH12_PREVIOUS_STAGES_FAILED >&2
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
  STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE19_FULL_NATIVE_GREEN \
  STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE21_FULL_NATIVE_GREEN \
  STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE23_FULL_NATIVE_GREEN \
  STAGE24_FULL_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/previous.log" || {
        echo "E_PATCH12_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/FreshStirPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt \
  src/main/kotlin/pastafari/PositionalNeighborPatchWrapper.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage25Tests.kt \
  src/test/kotlin/pastafari/Stage25BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage25.jar"; then
    echo E_PATCH12_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage25.jar" pastafari.Stage25Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH12_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE25_CORRECTED_QUERIES_GREEN_8640 \
  STAGE25_PRESERVED_LEGACY_RED_6912 \
  STAGE25_PRESERVED_INCIDENTAL_MATCH_1728 \
  STAGE25_PRESERVED_NUMERIC_CYCLES_12 \
  STAGE25_DIRECTION_STEPS_NORMATIVE_PASS \
  STAGE25_REVERSE_AND_WRAPAROUND_GREEN \
  STAGE25_INPUT_GUARDS_PASS STAGE25_PRODUCTION_POSITIONAL_GREEN \
  STAGE25_BOOT_REPLAY_GUARDS_PASS STAGE25_CONTEXT_OWNERSHIP_PASS \
  STAGE25_NATURAL_SAUCE_ORACLE_GREEN STAGE25_EARLIER_ROUTES_PASS \
  STAGE25_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH12_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage25.jar" pastafari.Stage25BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH12_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE25_BIGINT_CORRECTED_GREEN_25920 \
  STAGE25_BIGINT_PRESERVED_LEGACY_RED_20736 \
  STAGE25_BIGINT_PRESERVED_MATCH_5184 \
  STAGE25_BIGINT_PRESERVED_NUMERIC_CYCLES_36
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_PATCH12_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
printf '%s\n' STAGE25_FULL_NATIVE_GREEN
