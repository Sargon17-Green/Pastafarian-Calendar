#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage12-tests.sh > "$build_dir/stage12.log" 2>&1; then
    cat "$build_dir/stage12.log" >&2
    echo E_PATCH06_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage12.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
  STAGE12_NATIVE_EXPECTED_RED_COMPLETE
do
  grep -Fxq "$marker" "$build_dir/stage12.log" || {
    echo "E_PATCH06_PREVIOUS_MARKER_MISSING:$marker" >&2; exit 1;
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
  src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage13Tests.kt \
  src/test/kotlin/pastafari/Stage13BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage13.jar"; then
    echo E_PATCH06_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage13.jar" pastafari.Stage13Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH06_TESTS_FAILED >&2; exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE13_POSITIVE_LEGACY_CALLED_PASS \
  STAGE13_POSITIVE_NO_HIDDEN_STORE_REQUIRED_PASS \
  STAGE13_HIDDEN_K1_GREEN STAGE13_HIDDEN_K2_GREEN STAGE13_HIDDEN_K3_GREEN \
  STAGE13_HIDDEN_K4_GREEN STAGE13_HIDDEN_K5_GREEN STAGE13_HIDDEN_K6_GREEN \
  STAGE13_HIDDEN_K7_GREEN STAGE13_HIDDEN_GREEN_7 \
  STAGE13_PRESERVED_DISCOVERY06_RED_3 STAGE13_BRANCH_DISPATCH_COUNTS_PASS \
  STAGE13_HIDDEN_TRANSLATOR_GREEN_7 STAGE13_BOUNDARY_GUARDS_PASS \
  STAGE13_BOOT_REPLAY_GUARDS_PASS STAGE13_INVOCATION_OWNERSHIP_PASS \
  STAGE13_EARLIER_ROUTES_PASS STAGE13_COMPLETE_GREEN
do
  grep -Fxq "$marker" "$build_dir/patch.log" || {
    echo "E_PATCH06_MISSING_MARKER:$marker" >&2; exit 1;
  }
done
if ! kotlin -classpath "$build_dir/stage13.jar" pastafari.Stage13BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH06_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE13_BIGINT_VISIBLE_GREEN_5 STAGE13_BIGINT_HIDDEN_GREEN_35 \
  STAGE13_BIGINT_STONES_GREEN_175 STAGE13_BIGINT_PRESERVED_DISCOVERY06_RED_15
do
  grep -Fxq "$marker" "$build_dir/bigint.log" || {
    echo "E_PATCH06_BIGINT_MARKER_MISSING:$marker" >&2; exit 1;
  }
done
printf '%s\n' STAGE13_NATIVE_GREEN
