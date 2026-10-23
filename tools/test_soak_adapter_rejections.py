#!/usr/bin/env python3
"""Native black-box regressions for the soak TSV transport's fail-closed contract.

Runs the actual compiled executable; never mocks the calendar engine. A nonzero
exit invalidates a whole shard, including successfully streamed earlier rows.
"""
import argparse
import subprocess


INVALID_ROWS = (
    ("empty-input", ""),
    ("blank-row", "\n"),
    ("missing-column", "case\t0\n"),
    ("extra-column", "case\t0\t0\textra\n"),
    ("empty-id", "\t0\t0\n"),
    ("id-with-space", "bad id\t0\t0\n"),
    ("id-with-slash", "bad/id\t0\t0\n"),
    ("nonascii-id", "\u00e9\t0\t0\n"),
    ("plus-sign", "case\t+1\t0\n"),
    ("hex-number", "case\t0x10\t0\n"),
    ("scientific-notation", "case\t1e3\t0\n"),
    ("fractional-number", "case\t1.5\t0\n"),
    ("sign-only", "case\t-\t0\n"),
    ("space-in-number", "case\t 1\t0\n"),
    ("empty-number", "case\t\t0\n"),
    ("trailing-tab", "case\t0\t0\t\n"),
    ("nul-in-id", "a\x00b\t0\t0\n"),
    ("nul-in-number", "case\t1\x00\t0\n"),
)
INVALID_OPTIONS = (
    ("unknown-option", ("--other",)),
    ("duplicate-timing", ("--timing-ns", "--timing-ns")),
    ("duplicate-canonical", ("--canonical-indices", "--canonical-indices")),
    ("schema-with-timing", ("--schema", "--timing-ns")),
    ("canonical-schema-with-run", ("--schema-canonical", "--canonical-indices")),
)


def launch(binary, arguments, payload=b"", timeout=30):
    try:
        return subprocess.run(
            [binary, *arguments], input=payload, capture_output=True,
            check=False, timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        raise AssertionError("adapter timed out") from exc


def rejects(binary, arguments, payload, context, expected_line=None):
    result = launch(binary, arguments, payload)
    if result.returncode == 0 or result.stdout:
        raise AssertionError(
            f"{context}: invalid request accepted or wrote stdout: "
            f"status={result.returncode}, stdout={result.stdout[:150]!r}"
        )
    if b"SOAK_ADAPTER_ERROR\t" not in result.stderr:
        raise AssertionError(f"{context}: error marker missing: {result.stderr[:150]!r}")
    if expected_line is not None:
        if (b"line " + str(expected_line).encode() + b":") not in result.stderr:
            raise AssertionError(f"{context}: wrong failed row: {result.stderr[:150]!r}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("binary")
    parser.add_argument("compiler")
    args = parser.parse_args()
    checks = 0

    for mode, expected in (
        ("--schema", b"PASTAFARI_SOAK_TSV_V1\t"),
        ("--schema-canonical", b"PASTAFARI_SOAK_CANONICAL_V2\t"),
    ):
        result = launch(args.binary, (mode,))
        if result.returncode != 0 or not result.stdout.startswith(expected):
            raise AssertionError(f"{mode}: invalid schema banner")
        checks += 1

    for name, arguments in INVALID_OPTIONS:
        rejects(args.binary, arguments, b"", name)
        checks += 1

    for name, text in INVALID_ROWS:
        for mode in ((), ("--canonical-indices",)):
            rejects(
                args.binary, mode, text.encode("utf-8"), f"{name}:{mode}",
                expected_line=None if name == "empty-input" else 1,
            )
            checks += 1

    # A later invalid row must fail the entire batch, even when row 1 was
    # already emitted. The earlier stdout is evidence ONLY, not partial PASS.
    valid = b"proof\t-15055671\t-15055671\n"
    invalid = b"bad\t0x10\t0\n"
    for mode in ((), ("--canonical-indices",)):
        result = launch(
            args.binary, (*mode, "--timing-ns"), valid + invalid, timeout=1800
        )
        rows = result.stdout.splitlines()
        if result.returncode == 0 or len(rows) != 1:
            raise AssertionError(f"partial-batch:{mode}: wrong exit or row count")
        if len(rows[0].split(b"\t")) != 8 or not rows[0].startswith(b"proof\t"):
            raise AssertionError(f"partial-batch:{mode}: invalid surviving row")
        if b"SOAK_TIMING_NS\tproof\t" not in result.stderr:
            raise AssertionError(f"partial-batch:{mode}: timing marker missing")
        if b"SOAK_ADAPTER_ERROR\tline 2:" not in result.stderr:
            raise AssertionError(f"partial-batch:{mode}: missing line-2 failure")
        checks += 1

    print(f"SOAK_TRANSPORT_REJECTIONS={checks}/{checks}_PASS COMPILER={args.compiler}")
    print("SOAK_PARTIAL_SHARD_INVALIDATION=2/2_PASS")


if __name__ == "__main__":
    main()
