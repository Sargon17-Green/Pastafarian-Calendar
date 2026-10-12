#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage17-tests.sh > "$build_dir/previous.log" 2>&1; then
    cat "$build_dir/previous.log" >&2
    echo E_DISCOVERY09_PREVIOUS_STAGES_FAILED >&2
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
  STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE17_FULL_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/previous.log" || {
        echo "E_DISCOVERY09_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/test/kotlin/pastafari/Stage18Tests.kt \
  src/test/kotlin/pastafari/Stage18BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage18StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage18.jar"; then
    echo E_DISCOVERY09_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage18.jar" pastafari.Stage18Tests > "$build_dir/legacy-pours.log" 2>&1; then
    cat "$build_dir/legacy-pours.log" >&2
    echo E_DISCOVERY09_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/legacy-pours.log"
for marker in STAGE18_PATCH04_STONES_GREEN_46 \
  STAGE18_FIXED_POURS_EXPECTED_RED_714 STAGE18_INCIDENTAL_MATCH_6 \
  STAGE18_WRONG_POUR_CELLS_1800 STAGE18_ORDERED_SOURCES_ZERO_PATCH_PASS \
  STAGE18_REVERSED_ORDER_SCAR_PASS STAGE18_46_DROPS_REVERSED_RED_PASS \
  STAGE18_46_DROPS_IDENTITY_MATCH_PASS STAGE18_46_SNAPSHOT_CHAIN_PASS \
  STAGE18_NATURAL_ORACLE_46_EXPECTED_RED STAGE18_PRODUCTION_46_POURS_PASS \
  STAGE18_BOOT_REPLAY_GUARDS_PASS STAGE18_CONTEXT_OWNERSHIP_PASS \
  STAGE18_EARLIER_ROUTES_PASS STAGE18_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/legacy-pours.log" || {
        echo "E_DISCOVERY09_TEST_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage18.jar" pastafari.Stage18BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY09_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE18_BIGINT_EXPECTED_RED_4284 \
  STAGE18_BIGINT_INCIDENTAL_MATCH_36 STAGE18_BIGINT_WRONG_POUR_CELLS_10800
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_DISCOVERY09_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if kotlin -classpath "$build_dir/stage18.jar" pastafari.Stage18StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY09_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE18_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY09_STRICT_WRONG_REASON >&2; exit 1;
}
grep -Fq E_DISCOVERY09_STRICT_REVERSED_SOURCES_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY09_STRICT_WRONG_ERROR >&2; exit 1;
}
printf '%s\n' STAGE18_STRICT_RED_CONFIRMED STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE
