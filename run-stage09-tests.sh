#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage08-tests.sh > "$build_dir/stage08.log" 2>&1; then
    cat "$build_dir/stage08.log" >&2
    echo E_PATCH04_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage08.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
    STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
    STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
    STAGE08_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/stage08.log" || {
        echo "E_PATCH04_MISSING_PREVIOUS:$marker" >&2; exit 1;
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
    src/test/kotlin/pastafari/Stage09Tests.kt \
    src/test/kotlin/pastafari/Stage09BigIntegerTests.kt \
    -include-runtime -d "$build_dir/stage09.jar"; then
    echo E_PATCH04_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage09.jar" pastafari.Stage09Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH04_TEST_FAILED >&2; exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE09_PATCH_GREEN_0 STAGE09_PRESERVED_DISCOVERY04_RED_224 \
    STAGE09_GARBAGE_CAPTURE_PASS STAGE09_WHOLE_TABLE_GREEN_230 \
    STAGE09_SNAPSHOT_AND_CALLS_PASS STAGE09_OWNERSHIP_GUARDS_REPLAY_PASS \
    STAGE09_EARLIER_ROUTES_PASS STAGE09_COMPLETE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH04_MARKER_MISSING:$marker" >&2; exit 1;
    }
done
if ! kotlin -classpath "$build_dir/stage09.jar" pastafari.Stage09BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH04_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
grep -Fxq STAGE09_BIGINT_INDEPENDENT_GREEN_230 "$build_dir/bigint.log"
grep -Fxq STAGE09_BIGINT_GARBAGE_CAPTURE_PASS "$build_dir/bigint.log"
printf '%s\n' STAGE09_NATIVE_GREEN
