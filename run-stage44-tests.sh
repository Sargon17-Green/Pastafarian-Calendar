#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage43-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY22_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE43_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/main/kotlin/pastafari/LegacyYear5000UnfilteredRankAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage44Tests.kt \
  src/test/kotlin/pastafari/Stage44StrictRedTests.kt \
  -include-runtime -d "$work/stage44.jar"
if ! kotlin -classpath "$work/stage44.jar" pastafari.Stage44Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY22_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE44_REAL_GATE_396_PAIRS_ORACLE_GREEN \
  STAGE44_SYNTHETIC_64_CASES_128_EXPECTED_RED_128_MATCH \
  STAGE44_BIGINT_128_CASES_256_EXPECTED_RED_128_INVALID_THIRD_RANK \
  STAGE44_ELIGIBILITY_BOUNDARIES_GREEN \
  STAGE44_GUARDS_AND_IMMUTABILITY_GREEN \
  STAGE44_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage44.jar" pastafari.Stage44StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log"
  echo E_DISCOVERY22_STRICT_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY22_STRICT_FILTER_BEFORE_RANK_RED "$work/red.log"; then
  cat "$work/red.log"
  echo E_DISCOVERY22_STRICT_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE44_STRICT_RED_CONFIRMED
printf '%s\n' STAGE44_DISCOVERY_NATIVE_PASS
