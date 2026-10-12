#!/usr/bin/env sh
set -eu

build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage06-tests.sh > "$build_dir/stage06.log" 2>&1; then
    cat "$build_dir/stage06.log" >&2
    echo E_PATCH03_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/stage06.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
    STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
    STAGE06_EXPECTED_RED_5 STAGE06_MATCH_3 STAGE06_BIGINT_INDEPENDENT_PASS_549 \
    STAGE06_STRICT_RED_CONFIRMED STAGE06_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/stage06.log" || { echo "E_PATCH03_PREVIOUS_MARKER_MISSING:$marker" >&2; exit 1; }
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
    src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt src/main/kotlin/pastafari/LegacyPriorAdapter.kt src/main/kotlin/pastafari/PriorPatchWrapper.kt src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage07Tests.kt \
    src/test/kotlin/pastafari/Stage07BigIntegerTests.kt \
    -include-runtime -d "$build_dir/stage07.jar"; then
    echo E_PATCH03_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage07.jar" pastafari.Stage07Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH03_TEST_FAILED >&2; exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE07_WITNESSES_GREEN_8 STAGE07_PRESERVED_DISCOVERY03_RED_5 \
    STAGE07_MATRIX_GREEN_441 STAGE07_CONDITIONAL_WRAPPER_PASS \
    STAGE07_OWNERSHIP_AND_GUARDS_PASS STAGE07_EARLIER_ROUTES_PASS STAGE07_PATCH_GREEN_0
do
    grep -Fxq "$marker" "$build_dir/patch.log" || { echo "E_PATCH03_MARKER_MISSING:$marker" >&2; exit 1; }
done
if ! kotlin -classpath "$build_dir/stage07.jar" pastafari.Stage07BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH03_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE07_BIGINT_INDEPENDENT_GREEN_549 STAGE07_BIGINT_PRESERVED_LEGACY_RED_546
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || { echo "E_PATCH03_BIGINT_MARKER_MISSING:$marker" >&2; exit 1; }
done
printf '%s\n' STAGE07_NATIVE_GREEN
