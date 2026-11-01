#!/bin/sh
set -eu
mkdir -p obj bin
command -v gnatmake >/dev/null 2>&1 || { echo 'GNAT missing' >&2; exit 127; }
command -v timeout >/dev/null 2>&1 || { echo 'timeout missing' >&2; exit 127; }
command -v python3 >/dev/null 2>&1 || { echo 'Python missing' >&2; exit 127; }
timeout --signal=TERM --kill-after=5s 60s \
    python3 -B tests/stage16_sparse_window.py --selftest
gnatmake -gnat2022 -gnatW8 -gnata -gnatwa \
    -Isrc -Itests -D obj -o bin/stage16_sparse_window_observer \
    tests/stage16_sparse_window_observer.adb
log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT HUP INT TERM
status=0
timeout --signal=TERM --kill-after=5s 600s \
    ./bin/stage16_sparse_window_observer > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then
    echo "STAGE16_OBSERVER_EXIT_CODE=$status" >&2
    exit "$status"
fi
grep -Eq '^STAGE16_NATIVE_DOMAIN_REPEAT_ASSERTIONS= *131$' "$log_file"
timeout --signal=TERM --kill-after=5s 60s \
    python3 -B tests/stage16_sparse_window.py "$log_file"
