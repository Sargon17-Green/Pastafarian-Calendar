#!/usr/bin/env sh
set -eu

# Ailwirio'r pump cam gwreiddiol cyn profi'r graith newydd.
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage05-tests.sh > "$build_dir/stage05.log" 2>&1; then
    cat "$build_dir/stage05.log" >&2
    echo E_DISCOVERY03_STAGE05_BASELINE_FAILED >&2
    exit 1
fi
cat "$build_dir/stage05.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
    STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_PATCH_GREEN_0 \
    STAGE05_BIGINT_INDEPENDENT_PASS_418 STAGE05_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/stage05.log" || { echo "E_DISCOVERY03_MISSING_PREVIOUS:$marker" >&2; exit 1; }
done

if ! kotlinc \
    src/main/kotlin/pastafari/ExactInt.kt \
    src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
    src/main/kotlin/pastafari/LegacyRemainderAdapter.kt \
    src/main/kotlin/pastafari/SavePatchWrapper.kt \
    src/main/kotlin/pastafari/LegacyDayTagAdapter.kt \
    src/main/kotlin/pastafari/DayTagPatchWrapper.kt \
    src/main/kotlin/pastafari/LegacyDistanceAdapter.kt \
    src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage06Tests.kt \
    src/test/kotlin/pastafari/Stage06StrictRedTests.kt \
    src/test/kotlin/pastafari/Stage06BigIntegerTests.kt \
    -include-runtime -d "$build_dir/stage06.jar"; then
    echo E_DISCOVERY03_COMPILE_FAILED >&2; exit 1
fi
if ! kotlin -classpath "$build_dir/stage06.jar" pastafari.Stage06Tests > "$build_dir/discovery.log" 2>&1; then
    cat "$build_dir/discovery.log" >&2
    echo E_DISCOVERY03_TEST_FAILED >&2; exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE06_EXPECTED_RED_5 STAGE06_MATCH_3 STAGE06_MATRIX_PASS_441 \
    STAGE06_OWNERSHIP_GUARDS_PASS STAGE06_EARLIER_ROUTES_PASS STAGE06_NATIVE_EXPECTED_RED_PASS
do
    grep -Fxq "$marker" "$build_dir/discovery.log" || { echo "E_DISCOVERY03_MARKER_MISSING:$marker" >&2; exit 1; }
done
if ! kotlin -classpath "$build_dir/stage06.jar" pastafari.Stage06BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_DISCOVERY03_BIGINT_FAILED >&2; exit 1
fi
cat "$build_dir/bigint.log"
grep -Fxq STAGE06_BIGINT_INDEPENDENT_PASS_549 "$build_dir/bigint.log" || {
    echo E_DISCOVERY03_BIGINT_MARKER_MISSING >&2; exit 1;
}
# Mae'r methiant strict yn fwriadol: nid PATCH 03 mohono.
if kotlin -classpath "$build_dir/stage06.jar" pastafari.Stage06StrictRedTests > "$build_dir/strict.log" 2>&1; then
    echo E_DISCOVERY03_STRICT_RED_UNEXPECTEDLY_GREEN >&2; exit 1
fi
cat "$build_dir/strict.log"
grep -Fxq STAGE06_STRICT_EXPECTED_FAILURE "$build_dir/strict.log" || {
    echo E_DISCOVERY03_STRICT_FAILURE_WRONG_REASON >&2; exit 1;
}
printf '%s\n' STAGE06_STRICT_RED_CONFIRMED STAGE06_NATIVE_EXPECTED_RED_COMPLETE
