#!/bin/sh
set -eu
mkdir -p obj bin
command -v gnatmake >/dev/null 2>&1 || { echo 'GNAT missing' >&2; exit 127; }
command -v timeout >/dev/null 2>&1 || { echo 'timeout missing' >&2; exit 127; }
command -v python3 >/dev/null 2>&1 || { echo 'Python missing' >&2; exit 127; }

timeout --signal=TERM --kill-after=5s 180s \
    python3 -B tests/stage36_remote_twelve.py --selftest

gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage36_remote_twelve_observer \
    tests/stage36_remote_twelve_observer.adb

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT HUP INT TERM
status=0
timeout --signal=TERM --kill-after=5s 600s \
    ./bin/stage36_remote_twelve_observer > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then
    echo "STAGE36_OBSERVER_EXIT_CODE=$status" >&2
    exit "$status"
fi

grep -Eq '^STAGE36_NATIVE_REMOTE_TWELVE_ASSERTIONS= *131$' "$log_file"
timeout --signal=TERM --kill-after=5s 180s \
    python3 -B tests/stage36_remote_twelve.py "$log_file"
