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
  -include-runtime -d "$build_dir/stage28.jar"
kotlin -classpath "$build_dir/stage28.jar" pastafari.Stage28Tests | tee "$build_dir/stage28.log"
grep -Fxq STAGE28_EXPERIMENTAL_EXPECTED_RED_PASS "$build_dir/stage28.log"
grep -Fxq STAGE28_NORMATIVE_NEGATIVE_GATE_GREEN_24 "$build_dir/stage28.log"
printf '%s\n' STAGE28_DISCOVERY_NATIVE_PASS
