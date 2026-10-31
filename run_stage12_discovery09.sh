#!/bin/sh
set -eu
mkdir -p obj bin
if ! command -v gnatmake >/dev/null 2>&1; then
    printf '%s\n' 'GNAT అవసరం: gnatmake కనబడలేదు.' >&2
    exit 127
fi
gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage12_discovery09_tests \
    tests/stage12_discovery09_tests.adb
output="$(./bin/stage12_discovery09_tests)"
printf '%s\n' "$output"
printf '%s\n' "$output" | grep -Eq '^STAGE12_DISCOVERY09_ASSERTIONS= *1344$'
