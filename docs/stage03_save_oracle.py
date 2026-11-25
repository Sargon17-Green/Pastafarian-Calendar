#!/usr/bin/env python3
"""Independent Python-int oracle for Stage03 PATCH01: normative SAVE(x)."""
from __future__ import annotations

import argparse
import random
from hashlib import sha256
from pathlib import Path

M = (1 << 127) - 1
EXPECTED_CASES = 128
EXPECTED_RED_COUNT = 17
EXPECTED_MATCH_COUNT = 111
HEADER = (
    "case",
    "input",
    "modulus",
    "legacy_remainder",
    "save_result",
    "classification",
)


def legacy_remainder(value: int) -> int:
    """Ordinary Euclidean remainder for positive M."""
    return value % M


def save(value: int) -> int:
    """Normative SAVE(x) = 1 + ((x - 1) mod M)."""
    return 1 + ((value - 1) % M)


def rows() -> list[tuple[str, int, int, int, int, str]]:
    result: list[tuple[str, int, int, int, int, str]] = []
    seen_values: set[int] = set()
    seen_names: set[str] = set()

    def add(name: str, value: int) -> None:
        if name in seen_names:
            raise AssertionError(f"duplicate case name: {name}")
        if value in seen_values:
            return
        seen_names.add(name)
        seen_values.add(value)
        old_value = legacy_remainder(value)
        saved_value = save(value)
        classification = "EXPECTED_RED" if old_value != saved_value else "MATCH"
        result.append((name, value, M, old_value, saved_value, classification))

    boundaries = (
        ("EDGE_NEG2", -2),
        ("EDGE_NEG1", -1),
        ("EDGE_ZERO", 0),
        ("EDGE_ONE", 1),
        ("EDGE_TWO", 2),
        ("EDGE_M_MINUS_1", M - 1),
        ("EDGE_M_PLUS_1", M + 1),
        ("EDGE_NEG_M_MINUS_1", -M - 1),
        ("EDGE_NEG_M_PLUS_1", -M + 1),
        ("EDGE_2M_MINUS_1", 2 * M - 1),
        ("EDGE_2M_PLUS_1", 2 * M + 1),
        ("EDGE_NEG_2M_MINUS_1", -2 * M - 1),
        ("EDGE_NEG_2M_PLUS_1", -2 * M + 1),
        ("EDGE_16M_MINUS_1", 16 * M - 1),
        ("EDGE_16M", 16 * M),
        ("EDGE_16M_PLUS_1", 16 * M + 1),
    )
    for name, value in boundaries:
        add(name, value)

    # Three points around each of 16 signed multiples of M.
    for multiple in range(-8, 8):
        for delta in (-1, 0, 1):
            add(f"NEAR_K{multiple:+03d}_D{delta:+d}", multiple * M + delta)

    # Deterministic, signed, broad-width values; no external fixtures.
    rng = random.Random(0x535441474533)
    index = 0
    while len(result) < EXPECTED_CASES:
        bit_length = 128 + ((index * 97) % 1920)
        magnitude = rng.getrandbits(bit_length)
        value = magnitude if index % 2 == 0 else -magnitude
        if value % M == 0:
            value += 1
        add(f"RANDOM_{index:03d}", value)
        index += 1
        if index > 1000:
            raise AssertionError("could not generate the required unique vectors")

    if len(result) != EXPECTED_CASES:
        raise AssertionError(f"expected {EXPECTED_CASES} rows, got {len(result)}")
    if len(seen_values) != EXPECTED_CASES or len(seen_names) != EXPECTED_CASES:
        raise AssertionError("case identity is not unique")
    red_count = sum(row[5] == "EXPECTED_RED" for row in result)
    match_count = sum(row[5] == "MATCH" for row in result)
    if (red_count, match_count) != (EXPECTED_RED_COUNT, EXPECTED_MATCH_COUNT):
        raise AssertionError(
            f"classification counts differ: RED={red_count}, MATCH={match_count}"
        )

    for _, value, modulus, old_value, saved_value, classification in result:
        if modulus != M:
            raise AssertionError("non-normative modulus")
        if old_value != value % M:
            raise AssertionError("legacy remainder derivation mismatch")
        if saved_value != 1 + ((value - 1) % M):
            raise AssertionError("SAVE derivation mismatch")
        if not 1 <= saved_value <= M:
            raise AssertionError("SAVE result escaped 1..M")
        if save(value + M) != saved_value or save(value - M) != saved_value:
            raise AssertionError("SAVE periodicity failed")
        if (old_value != saved_value) != (value % M == 0):
            raise AssertionError("legacy/SAVE divergence classification failed")
        expected_classification = (
            "EXPECTED_RED" if old_value != saved_value else "MATCH"
        )
        if classification != expected_classification:
            raise AssertionError("classification label mismatch")
    return result


def render() -> bytes:
    lines = ["\t".join(HEADER)]
    lines.extend("\t".join(str(value) for value in row) for row in rows())
    return ("\n".join(lines) + "\n").encode("utf-8")


def validate(data: bytes) -> None:
    expected = render()
    if data != expected:
        raise SystemExit("FAIL: Stage03 TSV differs byte-for-byte from Python-int oracle")
    decoded = data.decode("utf-8", errors="strict").splitlines()
    if len(decoded) != EXPECTED_CASES + 1 or decoded[0] != "\t".join(HEADER):
        raise SystemExit("FAIL: Stage03 TSV header or row count is invalid")
    if any(len(line.split("\t")) != len(HEADER) for line in decoded[1:]):
        raise SystemExit("FAIL: Stage03 TSV row width is invalid")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--emit", type=Path, help="write deterministic TSV")
    mode.add_argument("--check", type=Path, help="check existing TSV byte-for-byte")
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

    print(f"PASS cases={EXPECTED_CASES} expected_red={EXPECTED_RED_COUNT} match={EXPECTED_MATCH_COUNT}")
    print("M=" + str(M))
    print("TSV_SHA256=" + sha256(data).hexdigest())


if __name__ == "__main__":
    main()
