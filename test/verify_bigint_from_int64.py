#!/usr/bin/env python3
"""Independent Python integer oracle for signed Int64 constructor boundary QA.

Contract: 96 unique input rows; five TSV columns (group, signed value, absolute,
opposite, successor). 14 Pascal assertions per row; no historical patch claim.
"""
import csv
from collections import Counter
from pathlib import Path

LOW = -(1 << 63)
HIGH = (1 << 63) - 1
EXPECTED = (
    [("ZERO", 0)]
    + [("SMALL", n) for n in range(-9, 0)]
    + [("SMALL", n) for n in range(1, 10)]
    + [("RADIX", sign * (10**k + delta)
       for k in range(3, 9) for sign in (-1, 1) for delta in (-1, 0, 1)]
    + [("POW2", sign * (2**k + delta)
       for k in (20, 31, 32, 40) for sign in (-1, 1) for delta in (-1, 0, 1)]
    + [("LIMIT", LOW + i) for i in range(9)]
    + [("LIMIT", HIGH - i) for i in range(8)]
)

def main():
    path = Path(__file__).with_name("bigint_from_int64_vectors.tsv")
    with path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))
    if len(EXPECTED) != 96 or len(rows) != 96:
        raise AssertionError(f"expected 96 rows, got {len(rows)}")
    seen = set()
    for index, (row, (group, number)) in enumerate(zip(rows, EXPECTED), 1):
        if len(row) != 5:
            raise AssertionError(f"row {index}: expected five fields")
        expected = [group, str(number), str(abs(number)), str(-number), str(number + 1)]
        if row != expected:
            raise AssertionError(f"row {index}: expected {expected!r}, got {row!r}")
        if not LOW <= number <= HIGH:
            raise AssertionError(f"row {index}: out of Int64 input range")
        if number in seen:
            raise AssertionError(f"row {index}: duplicate")
        seen.add(number)
    if Counter(r[0] for r in rows) != Counter(
        {"ZERO": 1, "SMALL": 18, "RADIX": 36, "POW2": 24, "LIMIT": 17}
    ):
        raise AssertionError("category distribution mismatch")
    if LOW not in seen or HIGH not in seen or 0 not in seen:
        raise AssertionError("required signed extrema absent")
    print("Python-int BigFromInt64: 96/96 distinct; 1 zero, 18 small, "
          "36 decimal-radix, 24 binary-boundary, 17 signed limits; "
          "Pascal assertions planned=1344; 0 divergences")

if __name__ == "__main__":
    main()
