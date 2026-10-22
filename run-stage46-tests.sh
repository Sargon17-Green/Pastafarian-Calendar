#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage45-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY23_PREVIOUS_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE45_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/main/kotlin/pastafari/LegacyYear5000RepeatedCandidateAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage46Tests.kt \
  src/test/kotlin/pastafari/Stage46StrictRedTests.kt \
  -include-runtime -d "$work/stage46.jar"
if ! kotlin -classpath "$work/stage46.jar" pastafari.Stage46Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY23_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE46_REAL_231_PAIRS_DUPLICATE_RED_GREEN \
  STAGE46_SYNTHETIC_64_RED_64_MATCH_64_EXTRA_RANK \
  STAGE46_BIGINT_128_TRIPLES_256_RED_128_EXTRA_RANK \
  STAGE46_INPUT_GUARDS_AND_BOUNDARIES_GREEN \
  STAGE46_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage46.jar" pastafari.Stage46StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY23_STRICT_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY23_STRICT_REPEATED_PAIR_RED "$work/red.log"; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY23_STRICT_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE46_STRICT_RED_CONFIRMED
printf '%s\n' STAGE46_DISCOVERY_NATIVE_PASS
