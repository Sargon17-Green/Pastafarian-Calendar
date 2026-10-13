#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage15-tests.sh > "$build_dir/stage15.log" 2>&1; then
    cat "$build_dir/stage15.log" >&2
    echo E_DISCOVERY08_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage15.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
  STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
  STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
  STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
  STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
  STAGE12_NATIVE_EXPECTED_RED_COMPLETE STAGE13_NATIVE_GREEN \
  STAGE14_NATIVE_EXPECTED_RED_COMPLETE STAGE15_FULL_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/stage15.log" || {
        echo "E_DISCOVERY08_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt src/main/kotlin/pastafari/PositionalNeighborPatchWrapper.kt src/main/kotlin/pastafari/LegacyGateGapRankAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage16Tests.kt \
  src/test/kotlin/pastafari/Stage16BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage16StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage16.jar"; then
    echo E_DISCOVERY08_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage16.jar" pastafari.Stage16Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY08_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE16_ZERO_BASED_HELPER_GREEN_720 \
  STAGE16_EXPECTED_RED_720 STAGE16_MATCH_0 STAGE16_SHIFTED_NUMERIC_719 \
  STAGE16_UNDEFINED_720_PASS STAGE16_RANK1_WRONG_ORDER_PASS \
  STAGE16_PRODUCTION_REAL_LEGACY_PASS STAGE16_PRODUCTION_720_UNDEFINED_PASS \
  STAGE16_BOOT_REPLAY_GUARDS_PASS STAGE16_CONTEXT_OWNERSHIP_PASS \
  STAGE16_EARLIER_ROUTES_PASS STAGE16_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || {
        echo "E_DISCOVERY08_TEST_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage16.jar" pastafari.Stage16BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY08_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE16_BIGINT_INDEPENDENT_RED_4320 \
  STAGE16_BIGINT_SHIFTED_NUMERIC_4314 STAGE16_BIGINT_UNDEFINED_6
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_DISCOVERY08_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if kotlin -classpath "$build_dir/stage16.jar" pastafari.Stage16StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY08_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE16_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY08_STRICT_WRONG_REASON >&2
    exit 1
}
grep -Fq E_DISCOVERY08_STRICT_RANK1_RED "$build_dir/strict.log" || {
    echo E_DISCOVERY08_STRICT_WRONG_ERROR >&2
    exit 1
}
printf '%s\n' STAGE16_STRICT_RED_CONFIRMED STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE
