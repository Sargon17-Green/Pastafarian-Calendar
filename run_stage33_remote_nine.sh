#!/bin/sh
set -eu
mkdir -p obj bin
command -v gnatmake >/dev/null 2>&1 || { echo 'GNAT missing' >&2; exit 127; }
command -v timeout >/dev/null 2>&1 || { echo 'timeout missing' >&2; exit 127; }
command -v python3 >/dev/null 2>&1 || { echo 'Python missing' >&2; exit 127; }

timeout --signal=TERM --kill-after=5s 180s \
    python3 -B tests/stage33_remote_nine.py --selftest

gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage33_remote_nine_observer \
    tests/stage33_remote_nine_observer.adb

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT HUP INT TERM
status=0
timeout --signal=TERM --kill-after=5s 600s \
    ./bin/stage33_remote_nine_observer > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then
    echo "STAGE33_OBSERVER_EXIT_CODE=$status" >&2
    exit "$status"
fi

grep -Eq '^STAGE33_NATIVE_REMOTE_NINE_ASSERTIONS= *131$' "$log_file"
timeout --signal=TERM --kill-after=5s 180s \
    python3 -B tests/stage33_remote_nine.py "$log_file"
