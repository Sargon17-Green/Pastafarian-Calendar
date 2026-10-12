#!/usr/bin/env sh
set -eu

# Rhaid cadw'r holl brofion Cam 1–2 a'r graith goch wreiddiol.
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
baseline_log="$build_dir/baseline.log"
if ! sh run-stage02-tests.sh > "$baseline_log" 2>&1; then
    cat "$baseline_log" >&2
    echo 'E_PATCH01_BASELINE_FAILED' >&2
    exit 1
fi
cat "$baseline_log"
for marker in \
    STAGE02_BASELINE_PROVENANCE_PASS_5 \
    STAGE01_PASS_66 \
    STAGE02_PERIODICITY_PASS_195 \
    STAGE02_FAR_ARITHMETIC_AND_REJECTION_PASS \
    STAGE02_BOUNDARY_AND_OWNERSHIP_PASS_7 \
    STAGE02_EXPECTED_RED_3 \
    STAGE02_STRICT_RED_CONFIRMED
do
    if ! grep -Fxq "$marker" "$baseline_log"; then
        printf 'E_PATCH01_BASELINE_MARKER_MISSING:%s\n' "$marker" >&2
        exit 1
    fi
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
    src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage03Tests.kt \
    src/test/kotlin/pastafari/Stage03ExtendedTests.kt \
    -include-runtime -d "$build_dir/stage03.jar"; then
    echo 'E_PATCH01_COMPILE' >&2
    exit 1
fi

patch_log="$build_dir/patch.log"
if ! kotlin -classpath "$build_dir/stage03.jar" pastafari.Stage03Tests > "$patch_log" 2>&1; then
    cat "$patch_log" >&2
    echo 'E_PATCH01_EXECUTION' >&2
    exit 1
fi
cat "$patch_log"
for marker in \
    STAGE03_SAVE_PATCH_GREEN_4 \
    STAGE03_LEGACY_SCAR_RED_3 \
    STAGE03_PATCH_GREEN_0 \
    STAGE03_LEGACY_ROUTE_PRESERVED \
    STAGE03_PERIODICITY_GREEN_195 \
    STAGE03_BOUNDARY_GREEN_7 \
    STAGE03_WIDE_ARITHMETIC_GREEN_129 \
    STAGE03_OWNERSHIP_AND_VALIDATION_GREEN \
    STAGE03_COMPLETE_GREEN
do
    if ! grep -Fxq "$marker" "$patch_log"; then
        printf 'E_PATCH01_MARKER_MISSING:%s\n' "$marker" >&2
        exit 1
    fi
done
extended_log="$build_dir/extended.log"
if ! kotlin -classpath "$build_dir/stage03.jar" pastafari.Stage03ExtendedTests > "$extended_log" 2>&1; then
    cat "$extended_log" >&2
    echo 'E_PATCH01_EXTENDED_EXECUTION' >&2
    exit 1
fi
cat "$extended_log"
if ! grep -Fxq 'STAGE03_EXTENDED_BIGINT_GREEN_921' "$extended_log"; then
    echo 'E_PATCH01_EXTENDED_MARKER_MISSING' >&2
    exit 1
fi
printf '%s\n' 'STAGE03_EXTENDED_NATIVE_GREEN'
printf '%s\n' 'STAGE03_NATIVE_GREEN'
