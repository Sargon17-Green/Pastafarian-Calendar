#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage21-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_DISCOVERY11_PREVIOUS_STAGES_FAILED >&2
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
  STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE21_FULL_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_DISCOVERY11_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage22Tests.kt \
  src/test/kotlin/pastafari/Stage22BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage22StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage22.jar"; then
    echo E_DISCOVERY11_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage22.jar" pastafari.Stage22Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY11_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE22_FIRST_STIR_GREEN_720 \
  STAGE22_SECOND_STIR_EXPECTED_RED_720 STAGE22_FINAL12_EXPECTED_RED_720 \
  STAGE22_MATCH_0 STAGE22_STALE_SUM_WITNESSES_720 \
  STAGE22_MIXING_FORMULA_INDEPENDENT_8640 \
  STAGE22_SIGNED_AND_HUGE_INPUTS_PASS STAGE22_INPUT_GUARDS_PASS \
  STAGE22_PRODUCTION_12_CACHED_PASS STAGE22_BOOT_REPLAY_GUARDS_PASS \
  STAGE22_CONTEXT_OWNERSHIP_PASS STAGE22_EARLIER_ROUTES_PASS \
  STAGE22_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || {
        echo "E_DISCOVERY11_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage22.jar" pastafari.Stage22BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY11_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE22_BIGINT_FIRST_GREEN_4320 \
  STAGE22_BIGINT_SECOND_RED_4320 STAGE22_BIGINT_FINAL_RED_4320 \
  STAGE22_BIGINT_STALE_STEPS_51840
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_DISCOVERY11_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if kotlin -classpath "$build_dir/stage22.jar" pastafari.Stage22StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY11_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE22_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY11_STRICT_WRONG_REASON >&2
    exit 1
}
grep -Fq E_DISCOVERY11_STRICT_STIR2_STALE_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY11_STRICT_WRONG_ERROR >&2
    exit 1
}
printf '%s\n' STAGE22_STRICT_RED_CONFIRMED STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE
