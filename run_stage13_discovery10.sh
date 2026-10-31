#!/bin/sh
set -eu
mkdir -p obj bin
if ! command -v gnatmake >/dev/null 2>&1; then
    printf '%s\n' 'GNAT అవసరం: gnatmake కనబడలేదు.' >&2
    exit 127
fi
if ! command -v timeout >/dev/null 2>&1; then
    printf '%s\n' 'GNU timeout అవసరం.' >&2
    exit 127
fi

gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage13_weave_tests \
    tests/stage13_weave_tests.adb
timeout --signal=TERM --kill-after=5s 180s ./bin/stage13_weave_tests

gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage13_discovery10_tests \
    tests/stage13_discovery10_tests.adb

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT HUP INT TERM
status=0
PC_STAGE13_DIAGNOSTIC=1 timeout --signal=TERM --kill-after=5s 600s \
    ./bin/stage13_discovery10_tests > "$log_file" 2>&1 || status=$?
cat "$log_file"

if [ "$status" -eq 124 ]; then
    printf '%s\n' 'STAGE13_DIAGNOSTIC_TIMEOUT_SECONDS=600' \
        'STAGE13_DISCOVERY10_NATIVE=NOT_ACCEPTED'
    exit 124
fi
if [ "$status" -ne 0 ]; then
    printf '%s\n' "STAGE13_DIAGNOSTIC_EXIT_CODE=$status" \
        'STAGE13_DISCOVERY10_NATIVE=NOT_ACCEPTED'
    exit "$status"
fi
grep -Eq '^STAGE13_DISCOVERY10_ASSERTIONS= *25$' "$log_file"
