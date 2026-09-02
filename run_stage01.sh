#!/bin/sh
set -eu

mkdir -p obj bin

if command -v gprbuild >/dev/null 2>&1; then
    gprbuild -p -P pastafari_calendar.gpr
elif command -v gnatmake >/dev/null 2>&1; then
    gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
        -Isrc -Itests -D obj -o bin/stage01_tests tests/stage01_tests.adb
else
    printf '%s\n' 'GNAT నిర్మాణ సాధనం దొరకలేదు: gprbuild లేదా gnatmake అవసరం.' >&2
    exit 127
fi

./bin/stage01_tests
