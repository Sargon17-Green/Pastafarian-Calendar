#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage07-tests.sh > "$build_dir/stage07.log" 2>&1; then
    cat "$build_dir/stage07.log" >&2
    echo E_DISCOVERY04_PREVIOUS_STAGES_FAILED >&2; exit 1
fi
cat "$build_dir/stage07.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
    STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
    STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/stage07.log" || {
        echo "E_DISCOVERY04_MISSING_PREVIOUS:$marker" >&2; exit 1;
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
    src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt src/main/kotlin/pastafari/LegacyPriorAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage08Tests.kt \
    src/test/kotlin/pastafari/Stage08BigIntegerTests.kt \
    src/test/kotlin/pastafari/Stage08StrictRedTests.kt \
    -include-runtime -d "$build_dir/stage08.jar"; then
    echo E_DISCOVERY04_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage08.jar" pastafari.Stage08Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY04_TEST_FAILED >&2; exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE08_ROW_2_EXPECTED_RED STAGE08_ROW_3_EXPECTED_RED \
    STAGE08_ROW_46_EXPECTED_RED STAGE08_EXPECTED_RED_224 STAGE08_MATCH_1 \
    STAGE08_ROWS_46_PASS STAGE08_INPLACE_SEQUENTIAL_PASS \
    STAGE08_OWNERSHIP_PASS STAGE08_GUARDS_REPLAY_PASS \
    STAGE08_EARLIER_ROUTES_PASS STAGE08_DISCOVERY_COMPLETE_EXPECTED_RED
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || {
        echo "E_DISCOVERY04_MARKER_MISSING:$marker" >&2; exit 1;
    }
done
if ! kotlin -classpath "$build_dir/stage08.jar" pastafari.Stage08BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY04_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
grep -Fxq STAGE08_BIGINT_INDEPENDENT_PASS_230 "$build_dir/bigint.log"
grep -Fxq STAGE08_BIGINT_NORMATIVE_RED_224 "$build_dir/bigint.log"
if kotlin -classpath "$build_dir/stage08.jar" pastafari.Stage08StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY04_STRICT_UNEXPECTEDLY_GREEN >&2; exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE08_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY04_STRICT_FAILURE_WRONG_REASON >&2; exit 1;
}
printf '%s\n' STAGE08_STRICT_RED_CONFIRMED STAGE08_NATIVE_EXPECTED_RED_COMPLETE
