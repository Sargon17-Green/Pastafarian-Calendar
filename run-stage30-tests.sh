#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage29-tests.sh > "$build_dir/prior.log" 2>&1; then
  cat "$build_dir/prior.log" >&2
  echo E_DISCOVERY15_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$build_dir/prior.log"
grep -Fxq STAGE29_FULL_NATIVE_GREEN "$build_dir/prior.log"
grep -Fxq STAGE28_DISCOVERY_NATIVE_PASS "$build_dir/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000OpeningAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage30Tests.kt \
  src/test/kotlin/pastafari/Stage30StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage30.jar"
if ! kotlin -classpath "$build_dir/stage30.jar" pastafari.Stage30Tests > "$build_dir/discovery.log" 2>&1; then
  cat "$build_dir/discovery.log" >&2
  echo E_DISCOVERY15_TESTS_FAILED >&2
  exit 1
fi
cat "$build_dir/discovery.log"
for marker in STAGE30_REAL_GATE_PAIRS_GREEN_25 \
  STAGE30_OPEN_GATE_EXPECTED_RED_25 \
  STAGE30_OTHER_BOUNDARIES_MATCH_100 \
  STAGE30_BOTH_GATE_SIGNS_GREEN \
  STAGE30_REAL_YEAR5000_ORACLE_BOUNDARY_GREEN \
  STAGE30_BIGINT_AND_INPUT_GUARDS_GREEN \
  STAGE30_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$build_dir/discovery.log"
done
if kotlin -classpath "$build_dir/stage30.jar" pastafari.Stage30StrictRedTests > "$build_dir/strict.log" 2>&1; then
  cat "$build_dir/strict.log"
  echo E_DISCOVERY15_STRICT_RED_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY15_STRICT_OPEN_GATE_RED "$build_dir/strict.log"; then
  cat "$build_dir/strict.log"
  echo E_DISCOVERY15_STRICT_RED_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE30_STRICT_RED_CONFIRMED
printf '%s\n' STAGE30_DISCOVERY_NATIVE_PASS
