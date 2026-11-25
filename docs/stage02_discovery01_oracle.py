#!/usr/bin/env python3
"""Independent Python-int oracle for Stage02 Discovery 01: REMAINDER_SAVE.

This file derives every expected value from the normative SAVE equation.
It imports no Pascal code and no fixtures or implementation from another branch.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
from pathlib import Path

M = (1 << 127) - 1
HEADER = (
    "case",
    "input",
    "modulus",
    "legacy_remainder",
    "save_result",
    "classification",
)
CASES = (
    ("ZERO", 0),
    ("M", M),
    ("2M", 2 * M),
    ("M_PLUS_1", M + 1),
)


def legacy_remainder(value: int) -> int:
    """The ordinary Euclidean remainder path being examined."""
    return value % M


def save(value: int) -> int:
    """Normative SAVE(x) = 1 + ((x - 1) mod M)."""
    return 1 + ((value - 1) % M)


def rows() -> list[tuple[str, int, int, int, int, str]]:
    result: list[tuple[str, int, int, int, int, str]] = []
    for name, value in CASES:
        old_value = legacy_remainder(value)
        saved_value = save(value)
        classification = "EXPECTED_RED" if old_value != saved_value else "MATCH"
        result.append((name, value, M, old_value, saved_value, classification))

    expected = [
        ("ZERO", 0, M, 0, M, "EXPECTED_RED"),
        ("M", M, M, 0, M, "EXPECTED_RED"),
        ("2M", 2 * M, M, 0, M, "EXPECTED_RED"),
        ("M_PLUS_1", M + 1, M, 1, 1, "MATCH"),
    ]
    if result != expected:
        raise AssertionError("Python-int derivation no longer matches the normative vectors")
    if sum(row[5] == "EXPECTED_RED" for row in result) != 3:
        raise AssertionError("Expected exactly three deliberate divergences")
    if sum(row[5] == "MATCH" for row in result) != 1:
        raise AssertionError("Expected exactly one matching control")
    return result


def render() -> bytes:
    lines = ["\t".join(HEADER)]
    lines.extend("\t".join(str(value) for value in row) for row in rows())
    return ("\n".join(lines) + "\n").encode("utf-8")


def validate(data: bytes) -> None:
    expected = render()
    if data != expected:
        raise SystemExit("FAIL: Discovery01 TSV differs byte-for-byte from Python-int oracle")
    decoded = data.decode("utf-8", errors="strict").splitlines()
    if len(decoded) != 5 or decoded[0] != "\t".join(HEADER):
        raise SystemExit("FAIL: Discovery01 TSV header or row count is invalid")
    if any(len(line.split("\t")) != 6 for line in decoded[1:]):
        raise SystemExit("FAIL: Discovery01 TSV row width is invalid")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--emit", type=Path, help="write the deterministic TSV")
    mode.add_argument("--check", type=Path, help="check an existing TSV byte-for-byte")
    mode.add_argument("--self-test", action="store_true", help="run oracle invariants")
    args = parser.parse_args()

    data = render()
    if args.emit is not None:
        args.emit.parent.mkdir(parents=True, exist_ok=True)
        args.emit.write_bytes(data)
        validate(args.emit.read_bytes())
    elif args.check is not None:
        validate(args.check.read_bytes())
    else:
        validate(data)

    print("PASS cases=4 expected_red=3 match=1")
    print("M=" + str(M))
    print("TSV_SHA256=" + sha256(data).hexdigest())


if __name__ == "__main__":
    main()
