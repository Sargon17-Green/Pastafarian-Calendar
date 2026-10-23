#!/usr/bin/env python3
"""Verify that native soak results stream before EOF, with exact timing IDs.

The central multi-implementation scheduler may keep stdin open indefinitely.
Batch-only tests do not detect adapters which buffer stdout until EOF.
"""
import argparse
import queue
import re
import subprocess
import threading

FIRST_ID = "stream_first"
SECOND_ID = "stream_second"
FIRST = b"stream_first\t-15055671\t-15055671\n"
# Same base-10 numbers: the leading zero must not invoke Boost's octal parser.
SECOND = b"stream_second\t-015055671\t-015055671\n"
INVALID = b"stream_invalid\t+1\t0\n"
TIMEOUT_SECONDS = 180


def new_process(binary, mode):
    process = subprocess.Popen(
        [binary, *mode, "--timing-ns"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0,
    )
    output = queue.Queue()

    def read_stdout():
        for line in process.stdout:
            output.put(line)

    thread = threading.Thread(target=read_stdout, daemon=True)
    thread.start()
    return process, output, thread


def feed_and_read(process, output, request, expected_id, canonical):
    if process.poll() is not None:
        raise AssertionError("native process exited before next request")
    process.stdin.write(request)
    process.stdin.flush()
    try:
        raw = output.get(timeout=TIMEOUT_SECONDS)
    except queue.Empty as exc:
        raise AssertionError("missing streamed response before stdin EOF") from exc
    if process.poll() is not None:
        raise AssertionError("native process unexpectedly exited while stdin open")
    parts = raw.rstrip(b"\n").split(b"\t")
    if len(parts) != 8 or parts[0] != expected_id.encode("ascii"):
        raise AssertionError(f"invalid response or out-of-order ID: {raw[:200]!r}")
    if parts[1] != b"-15055671" or parts[2] != b"-15055671":
        raise AssertionError("base-ten normalization failed")
    if canonical:
        for position, upper in ((4, 17), (6, 47)):
            if not re.fullmatch(rb"[1-9][0-9]*", parts[position]):
                raise AssertionError("non-decimal canonical index")
            if not 1 <= int(parts[position]) <= upper:
                raise AssertionError("canonical index out of range")
    return parts


def verify_timings(stderr, ids, context, expect_error):
    timing = []
    errors = []
    for line in stderr.splitlines():
        if line.startswith(b"SOAK_TIMING_NS\t"):
            parts = line.split(b"\t")
            if len(parts) != 3 or not re.fullmatch(rb"[0-9]+", parts[2]):
                raise AssertionError(f"{context}: malformed timing record: {line!r}")
            timing.append((parts[1].decode("ascii"), int(parts[2])))
        elif line.startswith(b"SOAK_ADAPTER_ERROR\t"):
            errors.append(line)
        else:
            raise AssertionError(f"{context}: unexpected stderr: {line!r}")
    if [item[0] for item in timing] != ids:
        raise AssertionError(f"{context}: lost/reordered timing records: {timing}")
    if any(ns < 0 for _, ns in timing):
        raise AssertionError(f"{context}: negative duration")
    if expect_error:
        if len(errors) != 1 or b"line 2:" not in errors[0]:
            raise AssertionError(f"{context}: missing line-2 rejection")
    elif errors:
        raise AssertionError(f"{context}: unexpected rejection")


def finish(process, output, thread, expected_exit, expected_rows):
    rc = process.wait(timeout=TIMEOUT_SECONDS)
    thread.join(timeout=10)
    if thread.is_alive():
        raise AssertionError("stdout reader failed to reach EOF")
    if rc != expected_exit:
        raise AssertionError(f"wrong process status: {rc} vs {expected_exit}")
    if not output.empty():
        raise AssertionError("extra stdout rows after process completion")
    return process.stderr.read()


def scenario(binary, mode, canonical, invalid_second):
    process, output, thread = new_process(binary, mode)
    try:
        row1 = feed_and_read(process, output, FIRST, FIRST_ID, canonical)
        if invalid_second:
            if process.poll() is not None:
                raise AssertionError("process stopped after first valid row")
            process.stdin.write(INVALID)
            process.stdin.flush()
            # Fail-closed must occur without requiring EOF from the scheduler.
            stderr = finish(process, output, thread, 1, 1)
            verify_timings(stderr, [FIRST_ID], "invalid-second", True)
        else:
            row2 = feed_and_read(process, output, SECOND, SECOND_ID, canonical)
            if row1[1:] != row2[1:]:
                raise AssertionError("identical pairs produced different dates")
            if process.poll() is not None:
                raise AssertionError("process exited before EOF")
            process.stdin.close()
            stderr = finish(process, output, thread, 0, 2)
            verify_timings(stderr, [FIRST_ID, SECOND_ID], "two-streamed", False)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait(timeout=10)
        if process.stdin and not process.stdin.closed:
            process.stdin.close()
        process.stdout.close()
        process.stderr.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("binary")
    parser.add_argument("compiler")
    args = parser.parse_args()
    scenarios = 0
    for mode in ((), ("--canonical-indices",)):
        for invalid_second in (False, True):
            scenario(args.binary, mode, bool(mode), invalid_second)
            scenarios += 1
    print(f"SOAK_INTERACTIVE_STREAM={scenarios}/{scenarios}_PASS COMPILER={args.compiler}")
    print("SOAK_INTERACTIVE_TIMING_ID_ORDER=PASS")
    print("SOAK_INTERACTIVE_FAILURE_BEFORE_EOF=PASS")


if __name__ == "__main__":
    main()
