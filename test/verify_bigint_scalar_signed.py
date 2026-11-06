#!/usr/bin/env python3
"""Independent Python-int oracle for 96 signed BigAddInt64/BigSubtractInt64 cases."""
import csv
import re
from pathlib import Path
from collections import Counter
LOW, HIGH = -(1 << 63), (1 << 63) - 1
CATEGORIES = ("MIN_EDGE", "MAX_EDGE", "NEAR_ZERO", "RADIX_BOUND",
              "BORROW_CARRY", "SIGN_CANCEL")
DEC = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")

def main():
    path = Path(__file__).with_name("bigint_scalar_signed_vectors.tsv")
    with path.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.reader(fh, delimiter="\t"))
    seen, counts, radices = set(), Counter(), set()
    b_values, a_values = set(), set()
    sums_zero = diffs_zero = max_digits = 0
    for i, fields in enumerate(rows, 1):
        if len(fields) != 5 or fields[0] not in CATEGORIES:
            raise AssertionError(f"row {i}: five fields/category required")
        cat, sa, sb, ss, sd = fields
        if not all(DEC.fullmatch(v) for v in fields[1:]):
            raise AssertionError(f"row {i}: noncanonical decimal")
        if (sa, sb) in seen:
            raise AssertionError(f"row {i}: duplicate pair")
        seen.add((sa, sb))
        a, b, s, d = map(int, (sa, sb, ss, sd))
        if len(sa.lstrip("-")) > 256 or not LOW <= b <= HIGH:
            raise AssertionError(f"row {i}: Int64 / 256-digit bound")
        if a+b != s or a-b != d:
            raise AssertionError(f"row {i}: Python-int oracle divergence")
        if cat == "MIN_EDGE" and b != LOW:
            raise AssertionError(f"row {i}: MIN_EDGE")
        if cat == "MAX_EDGE" and b != HIGH:
            raise AssertionError(f"row {i}: MAX_EDGE")
        if cat == "NEAR_ZERO" and (abs(a)>3 or abs(b)>3):
            raise AssertionError(f"row {i}: NEAR_ZERO")
        if cat == "SIGN_CANCEL" and (s != 0 and d != 0):
            raise AssertionError(f"row {i}: SIGN_CANCEL")
        if cat in ("RADIX_BOUND", "BORROW_CARRY") and not any(
                abs(abs(a)-10**(9*k))<=1 for k in range(1,29)):
            raise AssertionError(f"row {i}: radix boundary")
        for k in range(1,29):
            if abs(abs(a)-10**(9*k))<=1:
                radices.add(k)
        counts[cat]+=1
        b_values.add(b); a_values.add(a)
        sums_zero += (s == 0); diffs_zero += (d == 0)
        max_digits=max(max_digits,len(sa.lstrip("-")))
    if len(rows)!=96 or counts != Counter({c:16 for c in CATEGORIES}):
        raise AssertionError(f"cases/categories: {len(rows)}, {counts}")
    if radices != set(range(1,29)) or max_digits!=256:
        raise AssertionError("28 radix exponents / 256 digits")
    if not ({LOW,HIGH,0}<=b_values and 0 in a_values and
            any(a<0 for a in a_values) and any(a>0 for a in a_values)):
        raise AssertionError("Int64 extrema / signs / zeros")
    if sums_zero<8 or diffs_zero<8:
        raise AssertionError("cancellation/sign reversal coverage")
    print(f"Python-int scalar oracle: 96/96 unique, 6x16 categories,"
          f" 28 radix exponents, max A=256 digits,"
          f" zero sums={sums_zero}, zero differences={diffs_zero},"
          f" expected Pascal assertions=384; 0 divergences")
if __name__=="__main__":
    main()
