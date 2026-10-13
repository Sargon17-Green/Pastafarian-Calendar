#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage25-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_DISCOVERY13_PREVIOUS_STAGES_FAILED >&2
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
  STAGE24_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE25_FULL_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_DISCOVERY13_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage26Tests.kt \
  src/test/kotlin/pastafari/Stage26BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage26StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage26.jar"; then
    echo E_DISCOVERY13_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage26.jar" pastafari.Stage26Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY13_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE26_POSITIVE_EXPECTED_RED_922 \
  STAGE26_NEGATIVE_EXPECTED_RED_922 \
  STAGE26_TOTAL_ONE_BASED_GAP_RED_1844 \
  STAGE26_LEGACY_ILLEGAL_LOW_41_CONFIRMED \
  STAGE26_NORMATIVE_MAX_963_CONFIRMED \
  STAGE26_REJECTION_BOUNDARY_TESTS_8 \
  STAGE26_REJECTION_BOUNDARY_RED_7 \
  STAGE26_REJECTION_BOUNDARY_INCIDENTAL_MATCH_1 \
  STAGE26_IGNORED_REJECTION_CANDIDATES_6 \
  STAGE26_POSITIVE_NEGATIVE_NATURAL_SAUCE_PASS \
  STAGE26_INPUT_GUARDS_PASS \
  STAGE26_PRODUCTION_GATE_GAP_SCAR_PASS \
  STAGE26_BOOT_REPLAY_GUARDS_PASS \
  STAGE26_CONTEXT_OWNERSHIP_PASS \
  STAGE26_EARLIER_ROUTES_PASS \
  STAGE26_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || {
        echo "E_DISCOVERY13_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage26.jar" pastafari.Stage26BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY13_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE26_BIGINT_INPUTS_11064 \
  STAGE26_BIGINT_EXPECTED_RED_11064 \
  STAGE26_BIGINT_ILLEGAL_LOW_BOUND_CONFIRMED \
  STAGE26_BIGINT_CORRECT_HIGH_BOUND_CONFIRMED
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_DISCOVERY13_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if kotlin -classpath "$build_dir/stage26.jar" pastafari.Stage26StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY13_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE26_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY13_STRICT_WRONG_REASON >&2
    exit 1
}
grep -Fq E_DISCOVERY13_STRICT_GATE_RANK0_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY13_STRICT_WRONG_ERROR >&2
    exit 1
}
printf '%s\n' STAGE26_STRICT_RED_CONFIRMED STAGE26_FULL_NATIVE_EXPECTED_RED_COMPLETE
