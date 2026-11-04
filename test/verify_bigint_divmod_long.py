#!/usr/bin/env python3
"""Independent Stage1 DivMod long-operand reference using Python int.

Checks 96 deterministic TSV cases, quotient/remainder and category invariants.
This does not replicate the Pascal limb-based algorithm or authenticate
original historical patch files.
"""
import csv
import re
from collections import Counter
from pathlib import Path

EXPECTED_CATEGORIES = {"LT", "EQ", "ONE", "EXACT", "REM", "LIMB"}
EXPECTED_PER_CATEGORY = 16
SOURCE = Path(__file__).with_name("bigint_divmod_long_vectors.tsv")
CANONICAL = re.compile(r"(?:0|[1-9][0-9]*)\Z")

def main():
    counts = Counter()
    pairs = set()
    with SOURCE.open("r", encoding="utf-8", newline="") as stream:
        rows = list(csv.reader(stream, delimiter="\t"))
    for index, fields in enumerate(rows, 1):
        if len(fields) != 5:
            raise AssertionError(f"row {index}: five fields required")
        category, a_text, b_text, q_text, r_text = fields
        if category not in EXPECTED_CATEGORIES:
            raise AssertionError(f"row {index}: invalid category")
        if any(CANONICAL.fullmatch(text) is None for text in fields[1:]):
            raise AssertionError(f"row {index}: noncanonical decimal")
        if len(a_text) > 256 or len(b_text) > 256:
            raise AssertionError(f"row {index}: input longer than 256 digits")
        a, b, expect_q, expect_r = map(int, fields[1:])
        if a < 0 or b <= 0 or (a_text, b_text) in pairs:
            raise AssertionError(f"row {index}: invalid or duplicate operands")
        pairs.add((a_text, b_text))
        q, r = divmod(a, b)
        if (q, r) != (expect_q, expect_r):
            raise AssertionError(f"row {index}: expected {(expect_q, expect_r)}, oracle {(q, r)}")
        if category == "LT" and not a < b:
            raise AssertionError(f"row {index}: LT contract")
        if category == "EQ" and not a == b:
            raise AssertionError(f"row {index}: EQ contract")
        if category == "ONE" and not b == 1:
            raise AssertionError(f"row {index}: ONE contract")
        if category == "EXACT" and not (a > b and r == 0):
            raise AssertionError(f"row {index}: EXACT contract")
        if category == "REM" and not r > 0:
            raise AssertionError(f"row {index}: REM contract")
        if category == "LIMB":
            powers = [10 ** (9 * k) for k in range(1, 17)]
            if not any(abs(b - power) <= 1 for power in powers):
                raise AssertionError(f"row {index}: limb-boundary contract")
        counts[category] += 1
    if len(rows) != 96 or set(counts) != EXPECTED_CATEGORIES:
        raise AssertionError(f"count/category mismatch: {len(rows)}, {dict(counts)}")
    if any(count != EXPECTED_PER_CATEGORY for count in counts.values()):
        raise AssertionError(f"unbalanced categories: {dict(counts)}")
    print("Oracle Python DivMod longo: 96 pares, 6 grupos de 16; 384 verificacoes previstas; 0 divergencias.")

if __name__ == "__main__":
    main()
