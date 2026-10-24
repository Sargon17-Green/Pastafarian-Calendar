#!/usr/bin/env sh
set -eu
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT HUP INT TERM
if ! sh run-stage51-tests.sh > "$work/prior.log" 2>&1; then
  cat "$work/prior.log" >&2
  echo E_DISCOVERY26_PRIOR_STAGES_FAILED >&2
  exit 1
fi
cat "$work/prior.log"
grep -Fxq STAGE51_FULL_NATIVE_GREEN "$work/prior.log"
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyYear5000TieBreakAdapter.kt \
  src/main/kotlin/pastafari/LegacyYear5000ExclusiveAcceptanceAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage52Tests.kt \
  src/test/kotlin/pastafari/Stage52StrictRedTests.kt \
  -include-runtime -d "$work/stage52.jar"
if ! kotlin -classpath "$work/stage52.jar" pastafari.Stage52Tests > "$work/green.log" 2>&1; then
  cat "$work/green.log" >&2
  echo E_DISCOVERY26_MATRIX_FAILED >&2
  exit 1
fi
cat "$work/green.log"
for marker in STAGE52_REAL_231_PAIRS_STREAM_ORACLE_GREEN \
  STAGE52_SYNTHETIC_64_BOUNDARY_REDS_64_CONTROLS_GREEN \
  STAGE52_BIGINT_128_BOUNDARY_REDS_128_CONTROLS_GREEN \
  STAGE52_BOUNDARY_AND_GUARDS_GREEN \
  STAGE52_DISCOVERY_EXPECTED_RED_PASS
do
  grep -Fxq "$marker" "$work/green.log"
done
if kotlin -classpath "$work/stage52.jar" pastafari.Stage52StrictRedTests > "$work/red.log" 2>&1; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY26_STRICT_UNEXPECTED_GREEN >&2
  exit 1
fi
if ! grep -Fq E_DISCOVERY26_STRICT_ACCEPTANCE_BOUNDARY_RED "$work/red.log"; then
  cat "$work/red.log" >&2
  echo E_DISCOVERY26_STRICT_WRONG_FAILURE >&2
  exit 1
fi
printf '%s\n' STAGE52_STRICT_RED_CONFIRMED
printf '%s\n' STAGE52_DISCOVERY_NATIVE_PASS
