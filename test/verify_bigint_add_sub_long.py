#!/usr/bin/env python3
"""Independent Python-int oracle for signed long BigAdd/BigSubtract."""
import csv
import re
from collections import Counter
from pathlib import Path
SRC = Path(__file__).with_name("bigint_add_sub_long_vectors.tsv")
DEC = re.compile(r"(?:0|-?[1-9][0-9]*)$")
EXPECTED = {c: 16 for c in
            ("ADD_PP", "ADD_PN", "ADD_NP", "ADD_NN", "SUB_BORROW", "CANCEL")}
def main():
    with SRC.open(encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f, delimiter=chr(9)))
    counts = Counter()
    unique, bounds = set(), set()
    max_a = max_b = zero_sum = zero_diff = borrow = 0
    cascade = False
    for i, fields in enumerate(rows, 1):
        if len(fields) != 5 or fields[0] not in EXPECTED:
            raise AssertionError(f"linha {i}: cinco campos validos exigidos")
        if not all(DEC.fullmatch(v) for v in fields[1:]):
            raise AssertionError(f"linha {i}: decimal nao canonico")
        cat, sa, sb, ss, sd = fields
        if (sa, sb) in unique:
            raise AssertionError(f"linha {i}: par duplicado")
        unique.add((sa, sb))
        a, b, s, d = map(int, (sa, sb, ss, sd))
        if a + b != s or a - b != d:
            raise AssertionError(f"linha {i}: divergencia Python int")
        la, lb = len(sa.lstrip("-")), len(sb.lstrip("-"))
        max_a, max_b = max(max_a, la), max(max_b, lb)
        if la > 256 or lb > 256:
            raise AssertionError(f"linha {i}: limite de 256 algarismos")
        valid = {
            "ADD_PP": a > 0 and b > 0,
            "ADD_PN": a > 0 and b < 0,
            "ADD_NP": a < 0 and b > 0,
            "ADD_NN": a < 0 and b < 0,
            "SUB_BORROW": a > b > 0 and a % (10**9) == 0 and b < 10**9,
            "CANCEL": a > 0 and (a + b == 0 or a - b == 0),
        }
        if not valid[cat]:
            raise AssertionError(f"linha {i}: grupo incorreto")
        for k in range(1, 29):
            p = 10 ** (9 * k)
            if abs(abs(a) - p) <= 1 or abs(abs(b) - p) <= 1:
                bounds.add(k)
        zero_sum += int(a + b == 0)
        zero_diff += int(a - b == 0)
        borrow += int(cat == "SUB_BORROW")
        cascade |= cat == "ADD_PP" and a == 10**256 - 1 and b == 1
        counts[cat] += 1
    if len(rows) != 96 or counts != Counter(EXPECTED):
        raise AssertionError(f"contagens incorretas: {counts}")
    if (max_a, max_b, len(bounds), zero_sum, zero_diff, borrow, cascade) != (256, 256, 28, 8, 8, 16, True):
        raise AssertionError("cobertura: limites/zero/borrow/carry")
    print("Python int BigAdd/BigSubtract: 96/96 pares; 6x16 grupos; "
          "28 expoentes radix; 384 verificacoes esperadas; 0 divergencias")
if __name__ == "__main__":
    main()
