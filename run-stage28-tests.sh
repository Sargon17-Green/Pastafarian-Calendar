#!/usr/bin/env sh
set -eu
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
sh run-stage27-tests.sh
kotlinc src/main/kotlin/pastafari/ExactInt.kt \
  src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
  src/main/kotlin/pastafari/LegacyNegativeGateDirectionAdapter.kt \
  src/test/kotlin/pastafari/NormativeCore.kt \
  src/test/kotlin/pastafari/NormativeCalendar.kt \
  src/test/kotlin/pastafari/Stage28Tests.kt \
  src/test/kotlin/pastafari/Stage28StrictRedTests.kt \
  -include-runtime -d "$build_dir/stage28.jar"
kotlin -classpath "$build_dir/stage28.jar" pastafari.Stage28Tests > "$build_dir/stage28.log" 2>&1 || {
  cat "$build_dir/stage28.log"
  exit 1
}
cat "$build_dir/stage28.log"
grep -Fxq STAGE28_EXPERIMENTAL_EXPECTED_RED_PASS "$build_dir/stage28.log"
grep -Fxq STAGE28_NORMATIVE_NEGATIVE_GATE_GREEN_24 "$build_dir/stage28.log"
grep -Fxq STAGE28_ORDER_INDEPENDENCE_AND_REPEAT_GREEN "$build_dir/stage28.log"
grep -Fxq STAGE28_INPUT_GUARDS_AND_BIGINT_PASS "$build_dir/stage28.log"
if kotlin -classpath "$build_dir/stage28.jar" pastafari.Stage28StrictRedTests > "$build_dir/strict-red.log" 2>&1; then
  cat "$build_dir/strict-red.log"
  echo E_DISCOVERY14_STRICT_RED_UNEXPECTED_GREEN >&2
  exit 1
fi
grep -Fq E_DISCOVERY14_STRICT_NEGATIVE_GATE_DIRECTION_RED "$build_dir/strict-red.log" || {
  cat "$build_dir/strict-red.log"
  echo E_DISCOVERY14_STRICT_RED_WRONG_FAILURE >&2
  exit 1
}
printf '%s\n' STAGE28_STRICT_RED_CONFIRMED
printf '%s\n' STAGE28_DISCOVERY_NATIVE_PASS
