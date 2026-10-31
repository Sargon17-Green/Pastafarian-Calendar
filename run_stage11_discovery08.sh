#!/bin/sh
set -eu
mkdir -p obj bin
if ! command -v gnatmake >/dev/null 2>&1; then
    printf '%s\n' 'GNAT అవసరం: gnatmake కనబడలేదు.' >&2
    exit 127
fi
gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage11_discovery08_tests \
    tests/stage11_discovery08_tests.adb
output="$(./bin/stage11_discovery08_tests)"
printf '%s\n' "$output"
printf '%s\n' "$output" | grep -Eq '^STAGE11_DISCOVERY08_ASSERTIONS= *368$'
