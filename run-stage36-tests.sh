#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage35-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY18_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE35_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000MinExclusiveAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage36Tests.kt \
  src/test/kotlin/pastafari/Stage36StrictRedTests.kt \
  -include-runtime -d "$work/stage36.jar"
if ! kotlin -classpath "$work/stage36.jar" pastafari.Stage36Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY18_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE36_REAL_GATE_PROBES_450_PASS \
  STAGE36_SYNTHETIC_150_EXPECTED_RED_12_MATCH_138 \
  STAGE36_BIGINT_1024_EXPECTED_RED_512_MATCH_512 \
  STAGE36_ORACLE_AND_INPUT_GUARDS_PASS \
  STAGE36_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage36.jar" pastafari.Stage36StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log"
  echo E_DISCOVERY18_STRICT_UNEXPECTED_GREEN >&2
  exit 1
fi
grep -Fq E_DISCOVERY18_STRICT_MIN_252_RED "$work/red.log"
printf '%s\n' STAGE36_STRICT_RED_CONFIRMED
printf '%s\n' STAGE36_DISCOVERY_NATIVE_PASS
