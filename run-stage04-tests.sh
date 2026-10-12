#!/usr/bin/env sh
set -eu

# Mae pob cyfnod blaenorol yn parhau'n ofynnol; dim PATCH 02 yma.
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
baseline_log="$build_dir/stage03.log"
if ! sh run-stage03-tests.sh > "$baseline_log" 2>&1; then
    cat "$baseline_log" >&2
    echo 'E_DISCOVERY02_STAGE03_BASELINE_FAILED' >&2
    exit 1
fi
cat "$baseline_log"
for marker in \
    STAGE02_BASELINE_PROVENANCE_PASS_5 \
    STAGE01_PASS_66 \
    STAGE02_EXPECTED_RED_3 \
    STAGE02_STRICT_RED_CONFIRMED \
    STAGE03_LEGACY_SCAR_RED_3 \
    STAGE03_PATCH_GREEN_0 \
    STAGE03_EXTENDED_BIGINT_GREEN_921 \
    STAGE03_NATIVE_GREEN
do
    if ! grep -Fxq "$marker" "$baseline_log"; then
        printf 'E_DISCOVERY02_BASELINE_MISSING:%s\n' "$marker" >&2
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
    src/main/kotlin/pastafari/LegacyHiddenDropAdapter.kt \
    src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt src/main/kotlin/pastafari/LegacyPriorAdapter.kt src/main/kotlin/pastafari/PriorPatchWrapper.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage04Tests.kt \
    src/test/kotlin/pastafari/Stage04BigIntegerTests.kt \
    -include-runtime -d "$build_dir/stage04.jar"; then
    echo 'E_DISCOVERY02_COMPILE' >&2
    exit 1
fi

report="$build_dir/discovery02.log"
if ! kotlin -classpath "$build_dir/stage04.jar" pastafari.Stage04Tests > "$report" 2>&1; then
    cat "$report" >&2
    echo 'E_DISCOVERY02_EXECUTION' >&2
    exit 1
fi
cat "$report"
for marker in \
    STAGE04_EXPECTED_RED_3 \
    STAGE04_MATCH_2 \
    STAGE04_OWNERSHIP_PASS \
    STAGE04_PREVIOUS_ROUTES_PASS \
    STAGE04_BOOT_GUARDS_PASS \
    STAGE04_RANGE_RED_166_MATCH_165 \
    STAGE04_FAR_WIDE_PASS_4 \
    STAGE04_WIDE_METAMORPHIC_PASS_60 \
    STAGE04_REPLAY_REJECTION_PASS \
    STAGE04_COMPLETE_EXPECTED_RED
do
    if ! grep -Fxq "$marker" "$report"; then
        printf 'E_DISCOVERY02_MARKER_MISSING:%s\n' "$marker" >&2
        exit 1
    fi
done

# Cymharu'r gweithrediad cynhyrchu ag oracle Java annibynnol, prawf yn unig.
bigint_log="$build_dir/bigint.log"
if ! kotlin -classpath "$build_dir/stage04.jar" pastafari.Stage04BigIntegerTests > "$bigint_log" 2>&1; then
    cat "$bigint_log" >&2
    echo 'E_DISCOVERY02_BIGINT_EXECUTION' >&2
    exit 1
fi
cat "$bigint_log"
for marker in STAGE04_BIGINT_INDEPENDENT_PASS_409 STAGE04_BIGINT_RED_205_MATCH_204; do
    if ! grep -Fxq "$marker" "$bigint_log"; then
        printf 'E_DISCOVERY02_BIGINT_MARKER_MISSING:%s\n' "$marker" >&2
        exit 1
    fi
done

if kotlin -classpath "$build_dir/stage04.jar" pastafari.Stage04Tests --strict > "$build_dir/strict.log" 2>&1; then
    echo 'E_DISCOVERY02_STRICT_UNEXPECTED_GREEN' >&2
    exit 1
fi
if ! grep -Fq 'E_DISCOVERY02_NORMATIVE_DIFFERENCE:F,F+1,F+2' "$build_dir/strict.log"; then
    cat "$build_dir/strict.log" >&2
    echo 'E_DISCOVERY02_STRICT_WRONG_FAILURE' >&2
    exit 1
fi
printf '%s\n' 'STAGE04_STRICT_RED_CONFIRMED'
printf '%s\n' 'STAGE04_NATIVE_EXPECTED_RED_PASS'
