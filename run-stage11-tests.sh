#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage10-tests.sh > "$build_dir/stage10.log" 2>&1; then
    cat "$build_dir/stage10.log" >&2
    echo E_PATCH05_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage10.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE
do
  grep -Fxq "$marker" "$build_dir/stage10.log" || {
    echo "E_PATCH05_PREVIOUS_MARKER_MISSING:$marker" >&2; exit 1;
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
  src/main/kotlin/pastafari/LegacyPriorAdapter.kt src/main/kotlin/pastafari/PriorPatchWrapper.kt src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage11Tests.kt \
  src/test/kotlin/pastafari/Stage11BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage11.jar"; then
    echo E_PATCH05_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage11.jar" pastafari.Stage11Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH05_TESTS_FAILED >&2; exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE11_K1_GREEN STAGE11_K2_GREEN STAGE11_K3_GREEN \
  STAGE11_K4_GREEN STAGE11_K5_GREEN STAGE11_K6_GREEN STAGE11_K7_GREEN \
  STAGE11_PATCH_GREEN_7 STAGE11_PRESERVED_DISCOVERY05_RED_4 \
  STAGE11_FIXED_MIDPOINT_K4_GREEN STAGE11_WRONG_ACCESS_CALLED_7 \
  STAGE11_TRANSLATOR_7_PASS STAGE11_WRAPPER_GUARDS_PASS \
  STAGE11_CONTEXT_OWNERSHIP_PASS STAGE11_BOOT_REPLAY_GUARDS_PASS \
  STAGE11_EARLIER_ROUTES_PASS STAGE11_COMPLETE_GREEN
do
  grep -Fxq "$marker" "$build_dir/patch.log" || {
    echo "E_PATCH05_MARKER_MISSING:$marker" >&2; exit 1;
  }
done
if ! kotlin -classpath "$build_dir/stage11.jar" pastafari.Stage11BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH05_BIGINT_TESTS_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
grep -Fxq STAGE11_BIGINT_INDEPENDENT_GREEN_35 "$build_dir/bigint.log"
grep -Fxq STAGE11_BIGINT_PATCH04_STONES_GREEN_175 "$build_dir/bigint.log"
printf '%s\n' STAGE11_NATIVE_GREEN
