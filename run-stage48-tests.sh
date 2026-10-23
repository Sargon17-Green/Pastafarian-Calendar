#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage47-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY24_PRIOR_STAGE_FAILURE >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE47_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/main/kotlin/pastafari/LegacyYear5000FirstAnswerModuloAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage48Tests.kt \
  src/test/kotlin/pastafari/Stage48StrictRedTests.kt \
  -include-runtime -d "$work/stage48.jar"
if ! kotlin -classpath "$work/stage48.jar" pastafari.Stage48Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY24_MATRIX_FAILURE >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE48_REAL_231_GATE_PAIRS_STREAM_ORACLE_GREEN \
  STAGE48_SYNTHETIC_REJECT_DIFFERENTIALS_GREEN \
  STAGE48_BIGINT_MODULUS_EDGE_DIFFERENTIALS_GREEN \
  STAGE48_INPUT_GUARDS_GREEN \
  STAGE48_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage48.jar" pastafari.Stage48StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY24_UNEXPECTED_STRICT_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY24_STRICT_MODULO_BIAS_RED "$work/red.log"; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY24_WRONG_STRICT_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE48_STRICT_RED_CONFIRMED
printf '%s\n' STAGE48_DISCOVERY_NATIVE_PASS
