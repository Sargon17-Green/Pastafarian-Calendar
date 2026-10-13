#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage26-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_PATCH13_PREVIOUS_STAGES_FAILED >&2
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
  STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE23_FULL_NATIVE_GREEN \
  STAGE24_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE25_FULL_NATIVE_GREEN \
  STAGE26_FULL_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_PATCH13_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyGateGapRankAdapter.kt \
  src/main/kotlin/pastafari/GateGapRankPatchWrapper.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage27Tests.kt \
  src/test/kotlin/pastafari/Stage27BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage27.jar"; then
    echo E_PATCH13_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage27.jar" pastafari.Stage27Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH13_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE27_SHORT_CORRECTED_GREEN_1844 \
  STAGE27_SHORT_PRESERVED_LEGACY_RED_1844 \
  STAGE27_POSITIVE_922_NEGATIVE_922_GREEN \
  STAGE27_CORRECT_LOW_42_HIGH_963 \
  STAGE27_REJECTION_BOUNDARY_GREEN_8 \
  STAGE27_REJECTION_STARTS_6 \
  STAGE27_PRESERVED_BOUNDARY_LEGACY_RED_7 \
  STAGE27_PRESERVED_BOUNDARY_INCIDENTAL_MATCH_1 \
  STAGE27_REJECTED_ANSWER_SEQUENCE_VERIFIED_8 \
  STAGE27_WRAPAROUND_AND_LONG_REJECTION_PASS \
  STAGE27_POSITIVE_NEGATIVE_NATURAL_SAUCE_GREEN \
  STAGE27_INPUT_GUARDS_PASS \
  STAGE27_PRODUCTION_REJECTION_TRACE_GREEN \
  STAGE27_BOOT_REPLAY_GUARDS_PASS \
  STAGE27_CONTEXT_OWNERSHIP_PASS \
  STAGE27_EARLIER_ROUTES_PASS STAGE27_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH13_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage27.jar" pastafari.Stage27BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH13_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE27_BIGINT_CORRECTED_GREEN_11064 \
  STAGE27_BIGINT_PRESERVED_LEGACY_RED_11064 \
  STAGE27_BIGINT_REJECTION_GREEN_442 \
  STAGE27_BIGINT_REJECTION_POSITIVE_221_NEGATIVE_221 \
  STAGE27_BIGINT_REJECTION_FULL_TRACE_442 \
  STAGE27_BIGINT_REJECTION_LONG_STREAM_CONFIRMED \
  STAGE27_BIGINT_BOUNDARY_INCIDENTAL_MATCH_CONFIRMED
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_PATCH13_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
printf '%s\n' STAGE27_FULL_NATIVE_GREEN
