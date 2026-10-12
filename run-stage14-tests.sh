#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage13-tests.sh > "$build_dir/stage13.log" 2>&1; then
    cat "$build_dir/stage13.log" >&2
    echo E_DISCOVERY07_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage13.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
  STAGE12_NATIVE_EXPECTED_RED_COMPLETE STAGE13_NATIVE_GREEN
do
  grep -Fxq "$marker" "$build_dir/stage13.log" || {
    echo "E_DISCOVERY07_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage14Tests.kt \
  src/test/kotlin/pastafari/Stage14BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage14StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage14.jar"; then
    echo E_DISCOVERY07_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage14.jar" pastafari.Stage14Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY07_TEST_FAILED >&2
    exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE14_PHYSICAL_ROWS_GREEN_11 STAGE14_SENTINEL_ABSENT_PASS \
  STAGE14_GRIND1_EXPECTED_RED STAGE14_GRIND2_EXPECTED_RED \
  STAGE14_GRIND3_EXPECTED_RED STAGE14_GRIND4_EXPECTED_RED \
  STAGE14_GRIND5_EXPECTED_RED STAGE14_GRIND6_EXPECTED_RED \
  STAGE14_GRIND7_EXPECTED_RED STAGE14_GRIND8_EXPECTED_RED \
  STAGE14_GRIND9_EXPECTED_RED STAGE14_GRIND10_EXPECTED_RED \
  STAGE14_GRIND11_EXPECTED_RED STAGE14_EXPECTED_RED_11 STAGE14_MATCH_0 \
  STAGE14_GRIND1_IS_ROW2_PASS STAGE14_GRIND10_IS_ROW11_PASS \
  STAGE14_GRIND11_UNDEFINED_PASS STAGE14_PRODUCTION_PROBE_G1_PASS \
  STAGE14_PRODUCTION_UNDEFINED_G11_PASS STAGE14_PRODUCTION_REAL_ADAPTER_PASS \
  STAGE14_GUARDS_REPLAY_PASS STAGE14_CONTEXT_OWNERSHIP_PASS \
  STAGE14_EARLIER_ROUTES_PASS STAGE14_COMPLETE_EXPECTED_RED
do
  grep -Fxq "$marker" "$build_dir/discovery.log" || {
    echo "E_DISCOVERY07_MARKER_MISSING:$marker" >&2
    exit 1
  }
done
if ! kotlin -classpath "$build_dir/stage14.jar" pastafari.Stage14BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY07_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE14_BIGINT_INDEPENDENT_RED_66 \
  STAGE14_BIGINT_SHIFTED_NUMERIC_60 STAGE14_BIGINT_UNDEFINED_6
do
  grep -Fxq "$marker" "$build_dir/bigint.log" || {
    echo "E_DISCOVERY07_BIGINT_MARKER_MISSING:$marker" >&2
    exit 1
  }
done
if kotlin -classpath "$build_dir/stage14.jar" pastafari.Stage14StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY07_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE14_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY07_STRICT_WRONG_REASON >&2
    exit 1
}
grep -Fq E_DISCOVERY07_STRICT_GRIND1_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY07_STRICT_WRONG_ERROR >&2
    exit 1
}
printf '%s\n' STAGE14_STRICT_RED_CONFIRMED STAGE14_NATIVE_EXPECTED_RED_COMPLETE
