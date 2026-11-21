#!/bin/sh
set -eu
mkdir -p obj bin
command -v gprbuild >/dev/null 2>&1 || { echo 'GPRBuild missing for GMP native observer' >&2; exit 127; }
command -v timeout >/dev/null 2>&1 || { echo 'timeout missing' >&2; exit 127; }
command -v python3 >/dev/null 2>&1 || { echo 'Python missing' >&2; exit 127; }

timeout --signal=TERM --kill-after=5s 180s \
    python3 -B tests/stage41_remote_seventeen.py --selftest

gprbuild -p -j2 -P pastafari_calendar_stage41.gpr

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT HUP INT TERM
status=0
timeout --signal=TERM --kill-after=5s 600s \
    ./bin/stage41_remote_seventeen_observer > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then
    echo "STAGE41_OBSERVER_EXIT_CODE=$status" >&2
    exit "$status"
fi

grep -Eq '^STAGE41_NATIVE_REMOTE_SEVENTEEN_ASSERTIONS= *131$' "$log_file"
timeout --signal=TERM --kill-after=5s 180s \
    python3 -B tests/stage41_remote_seventeen.py "$log_file"
