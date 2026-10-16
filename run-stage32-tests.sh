#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
if ! sh run-stage31-tests.sh > "$build_dir/prior.log" 2>&1; then
  cat "$build_dir/prior.log" >&2
  echo E_DISCOVERY16_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$build_dir/prior.log"
grep -Fxq STAGE31_FULL_NATIVE_GREEN "$build_dir/prior.log"
grep -Fxq STAGE30_DISCOVERY_NATIVE_PASS "$build_dir/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000MinSevenAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage32Tests.kt \
  src/test/kotlin/pastafari/Stage32StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage32.jar"
if ! kotlin -classpath "$build_dir/stage32.jar" pastafari.Stage32Tests > "$build_dir/target.log" 2>&1; then
  cat "$build_dir/target.log" >&2
  echo E_DISCOVERY16_DIFFERENTIAL_FAILED >&2
  exit 1
fi
cat "$build_dir/target.log"
for marker in STAGE32_REAL_PAIRS_164_PROBES_492 \
  STAGE32_EXPECTED_MIN_SEVEN_RED_41 \
  STAGE32_OTHER_BOUNDARIES_MATCH_451 \
  STAGE32_BOTH_GATE_SIGNS_GREEN \
  STAGE32_BIGINT_PROBES_512_RED_128_MATCH_384 \
  STAGE32_YEAR5000_ORACLE_AND_INPUT_GUARDS_PASS \
  STAGE32_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$build_dir/target.log"
done
if kotlin -classpath "$build_dir/stage32.jar" pastafari.Stage32StrictRedTests > "$build_dir/red.log" 2>&1; then
  cat "$build_dir/red.log"
  echo E_DISCOVERY16_STRICT_RED_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY16_STRICT_MIN_SEVEN_RED "$build_dir/red.log"; then
  cat "$build_dir/red.log"
  echo E_DISCOVERY16_STRICT_RED_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE32_STRICT_RED_CONFIRMED
printf '%s\n' STAGE32_DISCOVERY_NATIVE_PASS
