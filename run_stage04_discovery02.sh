#!/bin/sh
set -eu
mkdir -p obj bin
if ! command -v gnatmake >/dev/null 2>&1; then
    printf '%s\n' 'GNAT అవసరం: gnatmake కనబడలేదు.' >&2
    exit 127
fi
gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage04_discovery02_tests \
    tests/stage04_discovery02_tests.adb
./bin/stage04_discovery02_tests
