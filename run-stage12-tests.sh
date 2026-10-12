#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage11-tests.sh > "$build_dir/stage11.log" 2>&1; then
    cat "$build_dir/stage11.log" >&2
    echo E_DISCOVERY06_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage11.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN
do
  grep -Fxq "$marker" "$build_dir/stage11.log" || {
    echo "E_DISCOVERY06_PREVIOUS_MARKER_MISSING:$marker" >&2; exit 1;
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
  src/main/kotlin/pastafari/PriorPatchWrapper.kt src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage12Tests.kt \
  src/test/kotlin/pastafari/Stage12BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage12StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage12.jar"; then
    echo E_DISCOVERY06_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage12.jar" pastafari.Stage12Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY06_TEST_FAILED >&2; exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE12_VISIBLE_PROBE_MATCH_1 STAGE12_VISIBLE_LEGACY_VALID_PASS \
  STAGE12_HIDDEN_SLOT_0_EXPECTED_RED STAGE12_HIDDEN_SLOT_-2_EXPECTED_RED \
  STAGE12_HIDDEN_SLOT_-6_EXPECTED_RED STAGE12_EXPECTED_RED_3 \
  STAGE12_MISSING_HISTORY_MATCH_0 STAGE12_PRODUCTION_VISIBLE_PROBE_PASS \
  STAGE12_PRODUCTION_HIDDEN_RED_3 STAGE12_CONTEXT_OWNER_PASS \
  STAGE12_GUARDS_REPLAY_PASS STAGE12_DIFFERENT_DAYS_OWNERSHIP_PASS \
  STAGE12_EARLIER_ROUTES_PASS STAGE12_COMPLETE_EXPECTED_RED
do
  grep -Fxq "$marker" "$build_dir/discovery.log" || {
    echo "E_DISCOVERY06_MARKER_MISSING:$marker" >&2; exit 1;
  }
done
if ! kotlin -classpath "$build_dir/stage12.jar" pastafari.Stage12BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY06_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE12_BIGINT_INDEPENDENT_GREEN_35 \
  STAGE12_BIGINT_PATCH04_STONES_GREEN_175 STAGE12_BIGINT_MISSING_HIDDEN_RED_15
do
  grep -Fxq "$marker" "$build_dir/bigint.log" || {
    echo "E_DISCOVERY06_BIGINT_MARKER_MISSING:$marker" >&2; exit 1;
  }
done
if kotlin -classpath "$build_dir/stage12.jar" pastafari.Stage12StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY06_STRICT_UNEXPECTED_GREEN >&2; exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE12_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY06_STRICT_WRONG_REASON >&2; exit 1
}
grep -Fq E_DISCOVERY06_STRICT_HIDDEN_HISTORY_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY06_STRICT_WRONG_ERROR >&2; exit 1
}
printf '%s\n' STAGE12_STRICT_RED_CONFIRMED STAGE12_NATIVE_EXPECTED_RED_COMPLETE
