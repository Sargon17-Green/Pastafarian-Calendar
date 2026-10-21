#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage41-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY21_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE41_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/main/kotlin/pastafari/LegacyYear5000PreSortRankAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage42Tests.kt \
  src/test/kotlin/pastafari/Stage42StrictRedTests.kt \
  -include-runtime -d "$work/stage42.jar"
if ! kotlin -classpath "$work/stage42.jar" pastafari.Stage42Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY21_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE42_REAL_GATE_231_PAIRS_ORACLE_GREEN \
  STAGE42_SYNTHETIC_RED_64_CASES_128_RANKS_MATCH_64_CASES_128_RANKS \
  STAGE42_BIGINT_128_TRIPLES_256_RED_128_MIDDLE_MATCH \
  STAGE42_INPUT_GUARDS_AND_OWNERSHIP_PASS \
  STAGE42_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage42.jar" pastafari.Stage42StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log"
  echo E_DISCOVERY21_STRICT_RED_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY21_STRICT_PRE_SORT_RANK_RED "$work/red.log"; then
  cat "$work/red.log"
  echo E_DISCOVERY21_STRICT_RED_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE42_STRICT_RED_CONFIRMED
printf '%s\n' STAGE42_DISCOVERY_NATIVE_PASS
