#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage23-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_DISCOVERY12_PREVIOUS_STAGES_FAILED >&2
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
  STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE23_FULL_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_DISCOVERY12_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt src/main/kotlin/pastafari/PositionalNeighborPatchWrapper.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage24Tests.kt \
  src/test/kotlin/pastafari/Stage24BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage24StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage24.jar"; then
    echo E_DISCOVERY12_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage24.jar" pastafari.Stage24Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY12_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE24_8640_NUMERIC_QUERIES_VERIFIED \
  STAGE24_EXPECTED_RED_6912 STAGE24_INCIDENTAL_MATCH_1728 \
  STAGE24_ALL_SIX_NUMERIC_CYCLES_12 \
  STAGE24_NONCYCLIC_ORDER_SEAL_PAIRS_1428 \
  STAGE24_FIRST_AND_DIRECTION_FORMULA_PASS \
  STAGE24_REVERSE_AND_WRAPAROUND_RED_PASS STAGE24_INPUT_GUARDS_PASS \
  STAGE24_PRODUCTION_NUMERIC_SCAR_PASS \
  STAGE24_BOOT_REPLAY_GUARDS_PASS STAGE24_CONTEXT_OWNERSHIP_PASS \
  STAGE24_NATURAL_SAUCE_INPUTS_PASS STAGE24_EARLIER_ROUTES_PASS \
  STAGE24_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || {
        echo "E_DISCOVERY12_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage24.jar" pastafari.Stage24BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY12_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE24_BIGINT_QUERIES_25920 \
  STAGE24_BIGINT_EXPECTED_RED_20736 \
  STAGE24_BIGINT_INCIDENTAL_MATCH_5184 \
  STAGE24_BIGINT_NUMERIC_CYCLES_36
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_DISCOVERY12_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if kotlin -classpath "$build_dir/stage24.jar" pastafari.Stage24StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY12_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE24_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY12_STRICT_WRONG_REASON >&2
    exit 1
}
grep -Fq E_DISCOVERY12_STRICT_NUMERIC_NEIGHBOR_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY12_STRICT_WRONG_ERROR >&2
    exit 1
}
printf '%s\n' STAGE24_STRICT_RED_CONFIRMED STAGE24_FULL_NATIVE_EXPECTED_RED_COMPLETE
