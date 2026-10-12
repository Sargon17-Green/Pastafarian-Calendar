#!/usr/bin/env sh
set -eu

# Cyn PATCH 02 rhaid ailbrofi pob cyfnod blaenorol, gan gynnwys y craith goch.
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
base="$build_dir/stage04.log"
if ! sh run-stage04-tests.sh > "$base" 2>&1; then
    cat "$base" >&2
    echo 'E_PATCH02_STAGE04_BASELINE_FAILED' >&2
    exit 1
fi
cat "$base"
for marker in \
    STAGE02_BASELINE_PROVENANCE_PASS_5 \
    STAGE01_PASS_66 \
    STAGE02_EXPECTED_RED_3 \
    STAGE02_STRICT_RED_CONFIRMED \
    STAGE03_PATCH_GREEN_0 \
    STAGE03_EXTENDED_BIGINT_GREEN_921 \
    STAGE03_NATIVE_GREEN \
    STAGE04_EXPECTED_RED_3 \
    STAGE04_MATCH_2 \
    STAGE04_BIGINT_INDEPENDENT_PASS_409 \
    STAGE04_STRICT_RED_CONFIRMED \
    STAGE04_NATIVE_EXPECTED_RED_PASS
do
    if ! grep -Fxq "$marker" "$base"; then
        printf 'E_PATCH02_BASELINE_MARKER_MISSING:%s\n' "$marker" >&2
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
    src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt src/main/kotlin/pastafari/LegacyPriorAdapter.kt src/main/kotlin/pastafari/PriorPatchWrapper.kt src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage05Tests.kt \
    src/test/kotlin/pastafari/Stage05BigIntegerTests.kt \
    -include-runtime -d "$build_dir/stage05.jar"; then
    echo 'E_PATCH02_COMPILE' >&2
    exit 1
fi

if ! kotlin -classpath "$build_dir/stage05.jar" pastafari.Stage05Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo 'E_PATCH02_EXECUTION' >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in \
    STAGE05_PATCH_GREEN_0 \
    STAGE05_WITNESSES_GREEN_5 \
    STAGE05_OWNERSHIP_PASS \
    STAGE05_DISCOVERY02_SCAR_RED_3 \
    STAGE05_EARLIER_ROUTES_PASS \
    STAGE05_GUARDS_AND_REPLAY_PASS \
    STAGE05_RANGE_GREEN_331 \
    STAGE05_WIDE_GREEN_60 \
    STAGE05_METRICS_AND_IMMUTABILITY_PASS \
    STAGE05_COMPLETE_GREEN
do
    if ! grep -Fxq "$marker" "$build_dir/patch.log"; then
        printf 'E_PATCH02_MARKER_MISSING:%s\n' "$marker" >&2
        exit 1
    fi
done

if ! kotlin -classpath "$build_dir/stage05.jar" pastafari.Stage05BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo 'E_PATCH02_BIGINT_EXECUTION' >&2
    exit 1
fi
cat "$build_dir/bigint.log"
if ! grep -Fxq 'STAGE05_BIGINT_INDEPENDENT_PASS_418' "$build_dir/bigint.log"; then
    echo 'E_PATCH02_BIGINT_MARKER_MISSING' >&2
    exit 1
fi
printf '%s\n' 'STAGE05_NATIVE_GREEN'
