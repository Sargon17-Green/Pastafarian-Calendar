#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage39-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY20_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE39_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage40Tests.kt \
  src/test/kotlin/pastafari/Stage40StrictRedTests.kt \
  -include-runtime -d "$work/stage40.jar"
if ! kotlin -classpath "$work/stage40.jar" pastafari.Stage40Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY20_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE40_REAL_GATE_ORACLE_231_PAIRS_GREEN \
  STAGE40_SYNTHETIC_64_EXPECTED_RED_64_MATCH \
  STAGE40_BIGINT_128_PAIRS_256_EXPECTED_RED \
  STAGE40_INPUT_GUARDS_GREEN \
  STAGE40_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage40.jar" pastafari.Stage40StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log"
  echo E_DISCOVERY20_STRICT_RED_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY20_STRICT_TIE_ORDER_RED "$work/red.log"; then
  cat "$work/red.log"
  echo E_DISCOVERY20_STRICT_RED_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE40_STRICT_RED_CONFIRMED
printf '%s\n' STAGE40_DISCOVERY_NATIVE_PASS
