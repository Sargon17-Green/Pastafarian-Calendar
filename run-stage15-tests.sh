#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage14-tests.sh > "$build_dir/stage14.log" 2>&1; then
    cat "$build_dir/stage14.log" >&2
    echo E_PATCH07_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage14.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
  STAGE12_NATIVE_EXPECTED_RED_COMPLETE STAGE13_NATIVE_GREEN \
  STAGE14_NATIVE_EXPECTED_RED_COMPLETE
do
  grep -Fxq "$marker" "$build_dir/stage14.log" || {
    echo "E_PATCH07_PREVIOUS_MARKER_MISSING:$marker" >&2; exit 1;
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
  src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage15Tests.kt \
  src/test/kotlin/pastafari/Stage15BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage15.jar"; then
    echo E_PATCH07_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage15.jar" pastafari.Stage15Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH07_TESTS_FAILED >&2; exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE15_GRIND1_GREEN STAGE15_GRIND2_GREEN STAGE15_GRIND3_GREEN \
  STAGE15_GRIND4_GREEN STAGE15_GRIND5_GREEN STAGE15_GRIND6_GREEN \
  STAGE15_GRIND7_GREEN STAGE15_GRIND8_GREEN STAGE15_GRIND9_GREEN \
  STAGE15_GRIND10_GREEN STAGE15_GRIND11_GREEN \
  STAGE15_TRANSLATED_ROWS_GREEN_11 STAGE15_LEGACY_SCAR_RED_11 \
  STAGE15_SENTINEL_SLOT_ZERO_PASS STAGE15_GRIND11_UNDEFINED_RECOVERED_PASS \
  STAGE15_PRODUCTION_ROUTE_PASS STAGE15_PRODUCTION_LAST_ROW_PASS \
  STAGE15_REAL_LEGACY_CALLED_PASS STAGE15_BOOT_REPLAY_GUARDS_PASS \
  STAGE15_CONTEXT_OWNERSHIP_PASS STAGE15_EARLIER_ROUTES_PASS \
  STAGE15_NATIVE_GREEN
do
  grep -Fxq "$marker" "$build_dir/patch.log" || {
    echo "E_PATCH07_MARKER_MISSING:$marker" >&2; exit 1;
  }
done
if ! kotlin -classpath "$build_dir/stage15.jar" pastafari.Stage15BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH07_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE15_BIGINT_CORRECTED_GREEN_66 \
  STAGE15_BIGINT_LEGACY_NUMERIC_RED_60 STAGE15_BIGINT_LEGACY_UNDEFINED_6
do
  grep -Fxq "$marker" "$build_dir/bigint.log" || {
    echo "E_PATCH07_BIGINT_MARKER_MISSING:$marker" >&2; exit 1;
  }
done
printf '%s\n' STAGE15_FULL_NATIVE_GREEN
