#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage53-tests.sh > "$work/prior.log" 2>&1; then
    cat "$work/prior.log" >&2
    echo E_DISCOVERY27_PRIOR_STAGE_FAILURE >&2
    exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE53_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/*.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage54Tests.kt \
    src/test/kotlin/pastafari/Stage54StrictRedTests.kt \
    -include-runtime -d "$work/stage54.jar"
if ! kotlin -classpath "$work/stage54.jar" pastafari.Stage54Tests > "$work/green.log" 2>&1; then
    cat "$work/green.log" >&2
    echo E_DISCOVERY27_MATRIX_FAILURE >&2
    exit 1
fi
cat "$work/green.log"
for marker in STAGE54_REAL_231_PAIRS_RANK_POSITION_EXPECTED_RED \
    STAGE54_SYNTHETIC_128_EXPECTED_RED_64_SINGLETON_MATCH \
    STAGE54_MANAGER_128_SESSIONS_GREEN \
    STAGE54_BIGINT_128_TRIPLES_384_EXPECTED_RED_128_WRAPS \
    STAGE54_GUARDS_REPLAY_METRICS_GREEN \
    STAGE54_DISCOVERY_EXPECTED_RED_PASS
do
    grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage54.jar" pastafari.Stage54StrictRedTests > "$work/red.log" 2>&1; then
    cat "$work/red.log" >&2
    echo E_DISCOVERY27_STRICT_UNEXPECTED_GREEN >&2
    exit 1
fi
if ! grep -Fq E_DISCOVERY27_STRICT_RANK_AS_INDEX_RED "$work/red.log"; then
    cat "$work/red.log" >&2
    echo E_DISCOVERY27_STRICT_WRONG_FAILURE >&2
    exit 1
fi
printf '%s\n' STAGE54_STRICT_RED_CONFIRMED
printf '%s\n' STAGE54_DISCOVERY_NATIVE_PASS
