#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage16-tests.sh > "$build_dir/prev.log" 2>&1; then
    cat "$build_dir/prev.log" >&2
    echo E_PATCH08_PREVIOUS_STAGES_FAILED >&2
    exit 1
fi
cat "$build_dir/prev.log"
for marker in STAGE01_PASS_66 STAGE02_EXPECTED_RED_3 STAGE03_NATIVE_GREEN \
 STAGE04_NATIVE_EXPECTED_RED_PASS STAGE05_NATIVE_GREEN \
 STAGE06_NATIVE_EXPECTED_RED_COMPLETE STAGE07_NATIVE_GREEN \
 STAGE08_NATIVE_EXPECTED_RED_COMPLETE STAGE09_NATIVE_GREEN \
 STAGE10_NATIVE_EXPECTED_RED_COMPLETE STAGE11_NATIVE_GREEN \
 STAGE12_NATIVE_EXPECTED_RED_COMPLETE STAGE13_NATIVE_GREEN \
 STAGE14_NATIVE_EXPECTED_RED_COMPLETE STAGE15_FULL_NATIVE_GREEN \
 STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE
do
    grep -Fxq "$marker" "$build_dir/prev.log" || {
        echo "E_PATCH08_PREVIOUS_MARKER_MISSING:$marker" >&2
        exit 1
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
  src/main/kotlin/pastafari/HiddenNearnessPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyPriorAdapter.kt \
  src/main/kotlin/pastafari/PriorPatchWrapper.kt \
  src/main/kotlin/pastafari/LegacyGrindTableAdapter.kt \
  src/main/kotlin/pastafari/LegacyPermutationOrderAdapter.kt src/main/kotlin/pastafari/LegacyFixedPourAdapter.kt src/main/kotlin/pastafari/LegacyInPlaceBowlAdapter.kt src/main/kotlin/pastafari/BowlSnapshotPatchWrapper.kt src/main/kotlin/pastafari/LegacyCachedStirAdapter.kt src/main/kotlin/pastafari/FreshStirPatchWrapper.kt src/main/kotlin/pastafari/LegacyNumericNeighborAdapter.kt \
  src/main/kotlin/pastafari/MonsterBootstrap.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage17Tests.kt \
  src/test/kotlin/pastafari/Stage17BigIntegerTests.kt \
  -include-runtime -d "$build_dir/stage17.jar"; then
    echo E_PATCH08_COMPILE_FAILED >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage17.jar" pastafari.Stage17Tests > "$build_dir/patch.log" 2>&1; then
    cat "$build_dir/patch.log" >&2
    echo E_PATCH08_TESTS_FAILED >&2
    exit 1
fi
cat "$build_dir/patch.log"
for marker in STAGE17_PATCHED_GREEN_720 STAGE17_UNIQUE_PERMUTATIONS_720 \
 STAGE17_PRESERVED_LEGACY_RED_720 STAGE17_LEGACY_NUMERIC_RED_719 \
 STAGE17_LEGACY_UNDEFINED_1 STAGE17_BOUNDARY_AND_PERIODICITY_PASS \
 STAGE17_PRODUCTION_FIRST_AND_LAST_GREEN STAGE17_REAL_LEGACY_CALL_PRESERVED \
 STAGE17_BOOT_REPLAY_GUARDS_PASS STAGE17_CONTEXT_OWNERSHIP_PASS \
 STAGE17_EARLIER_ROUTES_PASS STAGE17_NATIVE_GREEN
do
    grep -Fxq "$marker" "$build_dir/patch.log" || {
        echo "E_PATCH08_MISSING_MARKER:$marker" >&2
        exit 1
    }
done
if ! kotlin -classpath "$build_dir/stage17.jar" pastafari.Stage17BigIntegerTests > "$build_dir/bigint.log" 2>&1; then
    cat "$build_dir/bigint.log" >&2
    echo E_PATCH08_BIGINT_FAILED >&2
    exit 1
fi
cat "$build_dir/bigint.log"
for marker in STAGE17_BIGINT_CORRECTED_GREEN_4320 \
 STAGE17_BIGINT_PRESERVED_NUMERIC_RED_4314 \
 STAGE17_BIGINT_PRESERVED_UNDEFINED_6
do
    grep -Fxq "$marker" "$build_dir/bigint.log" || {
        echo "E_PATCH08_BIGINT_MISSING_MARKER:$marker" >&2
        exit 1
    }
done
printf '%s\n' STAGE17_FULL_NATIVE_GREEN
