#!/usr/bin/env python3
"""Independent unbounded-integer oracle for Stage 1 scalar/square QA.

The expected decimal result is checked with Python int arithmetic, not the
Pascal limb algorithm. Does not authenticate the Oct 12/13 historic patches.
"""
import csv
import re
from collections import Counter
from pathlib import Path

SOURCE = Path(__file__).with_name("bigint_scalar_square_vectors.tsv")
EXPECTED = {"M": 64, "U": 32, "S": 32}
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1
MAX_U32 = (1 << 32) - 1

def main():
    seen = set()
    counts = Counter()
    with SOURCE.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.reader(stream, delimiter="\t"))
    for n, fields in enumerate(rows, 1):
        if len(fields) != 4:
            raise AssertionError(f"row {n}: need four fields")
        kind, decimal, scalar, expected = fields
        if kind not in EXPECTED or not re.fullmatch(r"-?[0-9]+", decimal):
            raise AssertionError(f"row {n}: invalid kind or operand")
        if not re.fullmatch(r"-?[0-9]+", scalar):
            raise AssertionError(f"row {n}: invalid scalar")
        if (kind, decimal, scalar) in seen:
            raise AssertionError(f"row {n}: duplicate vector")
        seen.add((kind, decimal, scalar))
        a = int(decimal)
        b = int(scalar)
        if kind == "M" and not (MIN_I64 <= b <= MAX_I64):
            raise AssertionError(f"row {n}: out-of-range Int64")
        if kind == "U" and not (0 <= b <= MAX_U32):
            raise AssertionError(f"row {n}: out-of-range UInt32")
        if kind == "S" and b != 0:
            raise AssertionError(f"row {n}: nonzero square sentinel")
        result = a * a if kind == "S" else a * b
        if expected != str(result):
            raise AssertionError(f"row {n}: expected={expected}, independent={result}")
        counts[kind] += 1
    if dict(counts) != EXPECTED or len(rows) != 128:
        raise AssertionError(f"distribution error: {dict(counts)}")
    print("Oracle Python escalar/quadrado: 128 vetores (64 M, 32 U, 32 S); 256 verificacoes previstas; 0 divergencias.")

if __name__ == "__main__":
    main()
