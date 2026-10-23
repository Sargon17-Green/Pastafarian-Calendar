#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage49-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY25_PRIOR_STAGE_FAILURE >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE49_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/main/kotlin/pastafari/LegacyYear5000UnwrappedAnswerAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage50Tests.kt \
  src/test/kotlin/pastafari/Stage50StrictRedTests.kt \
  -include-runtime -d "$work/stage50.jar"
if ! kotlin -classpath "$work/stage50.jar" pastafari.Stage50Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY25_MATRIX_FAILURE >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE50_REAL_231_GATE_PAIRS_ORACLE_GREEN \
  STAGE50_SYNTHETIC_64_NO_WRAP_RED_64_CONTROLS_GREEN \
  STAGE50_BIGINT_128_NO_WRAP_RED_128_CONTROLS_GREEN \
  STAGE50_BOUNDS_AND_INPUT_GUARDS_GREEN \
  STAGE50_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage50.jar" pastafari.Stage50StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY25_STRICT_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY25_STRICT_MISSING_MODULUS_WRAP_RED "$work/red.log"; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY25_STRICT_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE50_STRICT_RED_CONFIRMED
printf '%s\n' STAGE50_DISCOVERY_NATIVE_PASS
