#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage37-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY19_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE37_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000ClosingExclusiveAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage38Tests.kt \
  src/test/kotlin/pastafari/Stage38StrictRedTests.kt \
  -include-runtime -d "$work/stage38.jar"
if ! kotlin -classpath "$work/stage38.jar" pastafari.Stage38Tests > "$work/results.log" 2>&1; then
  cat "$work/results.log" >&2
  echo E_DISCOVERY19_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/results.log"
for marker in STAGE38_REAL_PAIRS_25_PROBES_125_EXPECTED_RED_25_MATCH_100 \
  STAGE38_SYNTHETIC_150_EXPECTED_RED_18_MATCH_132 \
  STAGE38_BIGINT_1024_EXPECTED_RED_256_MATCH_768 \
  STAGE38_SELECTED_YEAR5000_CLOSE_AND_GUARDS_PASS \
  STAGE38_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/results.log"
done
if kotlin -classpath "$work/stage38.jar" pastafari.Stage38StrictRedTests > "$work/strict.log" 2>&1; then
  cat "$work/strict.log"
  echo E_DISCOVERY19_STRICT_UNEXPECTED_GREEN >&2
  exit 1
fi
grep -Fq E_DISCOVERY19_STRICT_CLOSE_GATE_RED "$work/strict.log"
printf '%s\n' STAGE38_STRICT_RED_CONFIRMED
printf '%s\n' STAGE38_DISCOVERY_NATIVE_PASS
