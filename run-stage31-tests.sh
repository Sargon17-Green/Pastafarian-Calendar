#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage30-tests.sh > "$build_dir/prior.log" 2>&1; then
    cat "$build_dir/prior.log" >&2
    echo E_PATCH15_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/prior.log"
grep -Fxq STAGE29_FULL_NATIVE_GREEN "$build_dir/prior.log"
grep -Fxq STAGE30_STRICT_RED_CONFIRMED "$build_dir/prior.log"
grep -Fxq STAGE30_DISCOVERY_NATIVE_PASS "$build_dir/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage31Tests.kt \
    -include-runtime -d "$build_dir/stage31.jar"
if ! kotlin -classpath "$build_dir/stage31.jar" pastafari.Stage31Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH15_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE31_REAL_GATE_CORRECTED_GREEN_125 \
    STAGE31_PRESERVED_LEGACY_RED_25_MATCH_100 \
    STAGE31_CANDIDATE_MATRIX_GREEN_495 \
    STAGE31_BIGINT_CORRECTED_GREEN_1920_LEGACY_RED_384 \
    STAGE31_REAL_SELECTED_YEAR5000_BOUNDARY_GREEN \
    STAGE31_GUARDS_METRICS_REPLAY_OWNERSHIP_PASS \
    STAGE31_PATCH_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log"
done
printf '%s\n' STAGE31_FULL_NATIVE_GREEN
