#!/usr/bin/env python3
"""Independent signed Euclidean-modulo oracle using Python arbitrary integers.

Each fixture carries (category, A, D, q, r), with q = A // D, r = A % D.
This does not implement the Pascal base-10^9 arithmetic or authenticate
historical October patch sources.
"""
import csv
import re
from collections import Counter
from pathlib import Path

SOURCE = Path(__file__).with_name("bigint_regular_mod_signed_vectors.tsv")
SIGNED = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
POSITIVE = re.compile(r"[1-9][0-9]*\Z")
COUNTS = {"NEG_EXACT": 32, "NEG_REM": 32, "POS": 16, "ZERO": 16}

def main():
    with SOURCE.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.reader(stream, delimiter="\t"))
    count = Counter()
    pairs = set()
    boundaries = set()
    seen_256_a = seen_256_d = False
    for index, fields in enumerate(rows, 1):
        if len(fields) != 5:
            raise AssertionError(f"row {index}: exactly 5 columns required")
        cat, a_s, d_s, q_s, r_s = fields
        if cat not in COUNTS:
            raise AssertionError(f"row {index}: unknown category")
        if not all(SIGNED.fullmatch(t) for t in (a_s,q_s,r_s)) or not POSITIVE.fullmatch(d_s):
            raise AssertionError(f"row {index}: noncanonical decimal")
        if len(a_s.lstrip("-")) > 256 or len(d_s) > 256:
            raise AssertionError(f"row {index}: operand exceeds 256 digits")
        if (a_s,d_s) in pairs:
            raise AssertionError(f"row {index}: repeated pair")
        pairs.add((a_s,d_s))
        a,d,q_exp,r_exp=map(int,(a_s,d_s,q_s,r_s))
        q,r=divmod(a,d)
        if (q,r)!=(q_exp,r_exp):
            raise AssertionError(f"row {index}: stored q/r differ from Python oracle")
        if not (0 <= r < d and a == q*d+r):
            raise AssertionError(f"row {index}: Euclidean identity violated")
        if cat == "NEG_EXACT" and not (a < 0 and r == 0):
            raise AssertionError(f"row {index}: negative exact contract")
        if cat == "NEG_REM" and not (a < 0 and r > 0):
            raise AssertionError(f"row {index}: negative nonmultiple contract")
        if cat == "POS" and not a > 0:
            raise AssertionError(f"row {index}: positive contract")
        if cat == "ZERO" and not a == 0:
            raise AssertionError(f"row {index}: zero contract")
        for k in range(1,29):
            if abs(d - 10**(9*k)) <= 1:
                boundaries.add(k)
        seen_256_a |= len(a_s.lstrip("-")) == 256
        seen_256_d |= len(d_s) == 256
        count[cat] += 1
    if len(rows)!=96 or count != Counter(COUNTS):
        raise AssertionError(f"case/category counts incorrect: {len(rows)}, {count}")
    if len(boundaries)<20 or not (seen_256_a and seen_256_d):
        raise AssertionError("radix boundaries/256-digit extremes missing")
    print("Oracle Python modulo assinado: 96/96 pares; 4 grupos; "
          "384 verificacoes esperadas; 0 divergencias.")

if __name__ == "__main__":
    main()
