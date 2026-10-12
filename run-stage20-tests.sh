#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage19-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_DISCOVERY10_PREVIOUS_STAGES_FAILED >&2
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
  STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE STAGE19_FULL_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_DISCOVERY10_PREVIOUS_MARKER_MISSING:$marker" >&2
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
  src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage20Tests.kt \
  src/test/kotlin/pastafari/Stage20BigIntegerTests.kt \
  src/test/kotlin/pastafari/Stage20StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage20.jar"; then
    echo E_DISCOVERY10_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage20.jar" pastafari.Stage20Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY10_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE20_SINGLE_EXPECTED_RED_720 STAGE20_SINGLE_MATCH_0 \
  STAGE20_SINGLE_FIRST_WRITE_GREEN_720 \
  STAGE20_SINGLE_WRONG_POSITIONS_3600 \
  STAGE20_LIVE_NEIGHBOR_READ_WITNESSES_720 \
  STAGE20_INPUT_GUARDS_PASS \
  STAGE20_46_IDENTITY_EXPECTED_RED STAGE20_46_REVERSE_EXPECTED_RED \
  STAGE20_46_SNAPSHOTS_ISOLATED_PASS \
  STAGE20_NATURAL_46_ORACLE_EXPECTED_RED \
  STAGE20_PRODUCTION_46_INPLACE_PASS \
  STAGE20_BOOT_REPLAY_GUARDS_PASS STAGE20_CONTEXT_OWNERSHIP_PASS \
  STAGE20_EARLIER_ROUTES_PASS STAGE20_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || {
        echo "E_DISCOVERY10_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage20.jar" pastafari.Stage20BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY10_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE20_BIGINT_EXPECTED_RED_4320 \
  STAGE20_BIGINT_MATCH_0 STAGE20_BIGINT_FIRST_WRITE_GREEN_4320 \
  STAGE20_BIGINT_LIVE_WRONG_WRITES_21600
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_DISCOVERY10_BIGINT_MARKER_MISSING:$marker" >&2
        exit 1
    }
done
if kotlin -classpath "$build_dir/stage20.jar" pastafari.Stage20StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY10_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq 'STAGE20_STRICT_EXPECTED_FAILURE' "$build_dir/strict.log" || {
    echo E_DISCOVERY10_STRICT_WRONG_REASON >&2
    exit 1
}
grep -Fq 'E_DISCOVERY10_STRICT_INPLACE_POSITION2_RED' "$build_dir/strict.log" || {
    echo E_DISCOVERY10_STRICT_WRONG_ERROR >&2
    exit 1
}
printf '%s\n' STAGE20_STRICT_RED_CONFIRMED STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE
