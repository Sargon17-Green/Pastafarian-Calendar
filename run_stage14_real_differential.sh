#!/bin/sh
set -eu
mkdir -p obj bin
command -v gnatmake >/dev/null 2>&1 || { echo 'GNAT13 gnatmake missing' >&2; exit 127; }
command -v timeout >/dev/null 2>&1 || { echo 'GNU timeout missing' >&2; exit 127; }
command -v python3 >/dev/null 2>&1 || { echo 'Python 3 missing' >&2; exit 127; }

# Independent real-day reference is tested before reading Ada output.
timeout --signal=TERM --kill-after=5s 60s \
    python3 -B tests/stage14_real_differential.py --selftest

gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage14_real_observer \
    tests/stage14_real_observer.adb
log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT HUP INT TERM
status=0
timeout --signal=TERM --kill-after=5s 600s \
    ./bin/stage14_real_observer > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then
    echo "STAGE14_OBSERVER_EXIT_CODE=$status" >&2
    exit "$status"
fi
grep -Eq '^STAGE14_NATIVE_DOMAIN_REPEAT_ASSERTIONS= *21$' "$log_file"
timeout --signal=TERM --kill-after=5s 60s \
    python3 -B tests/stage14_real_differential.py "$log_file"
