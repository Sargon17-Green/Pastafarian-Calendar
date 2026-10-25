#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage54-tests.sh > "$work/prior.log" 2>&1; then
    cat "$work/prior.log" >&2
    echo E_PATCH27_PRIOR_STAGE_FAILURE >&2
    exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE54_STRICT_RED_CONFIRMED "$work/prior.log"
grep -Fxq STAGE54_DISCOVERY_NATIVE_PASS "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage55Tests.kt \
    -include-runtime -d "$work/stage55.jar"
if ! kotlin -classpath "$work/stage55.jar" pastafari.Stage55Tests > "$work/green.log" 2>&1; then
    cat "$work/green.log" >&2
    echo E_PATCH27_TEST_FAILURE >&2
    exit 1
fi
cat "$work/green.log"
for marker in STAGE55_REAL_231_PAIRS_43_CORRECTED_GREEN_43_LEGACY_RED \
    STAGE55_SYNTHETIC_128_CORRECTED_GREEN_128_LEGACY_RED_64_MATCH \
    STAGE55_MANAGER_128_SESSIONS_GREEN \
    STAGE55_BIGINT_128_TRIPLES_384_GREEN_384_LEGACY_RED_128_WRAPS \
    STAGE55_TIE_64_PAIRS_128_RANKS_GREEN \
    STAGE55_GUARDS_REPLAY_METRICS_GREEN \
    STAGE55_PATCH_NATIVE_GREEN
do
    grep -Fxq "$marker" "$work/green.log"
done
printf '%s\n' STAGE55_FULL_NATIVE_GREEN
