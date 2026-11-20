#!/usr/bin/env python3
"""Independent Python-int oracle for 512-digit quotient thresholds B and 2*B.

Produces 96 deterministic unique (A,B,Q,R) rows in six groups of 16.
All A and B are exactly 512 decimal digits; B>0 and A>=0.
"""
from collections import Counter
from hashlib import sha256
from pathlib import Path

GROUPS = (
    "BELOW_B", "EXACT_B", "ABOVE_B",
    "BELOW_2B", "EXACT_2B", "ABOVE_2B",
)
EXPECTED_Q = (0, 1, 1, 1, 2, 2)
OUTPUT = Path(__file__).with_name("bigint_floor_div_positive_quotient512.tsv")


def divisor(index):
    # Hash-derived decimal limbs avoid sharing the Pascal implementation's radix.
    suffix = "".join(
        f"{int.from_bytes(sha256(f'quotient512-v1:{index}:{j}'.encode('ascii')).digest(), 'big') % (10**78):078d}"
        for j in range(7)
    )[:511]
    return int(str(1 + index % 4) + suffix)


def vectors():
    for index in range(16):
        b = divisor(index)
        dividends = (b - 1, b, b + 1, 2 * b - 1, 2 * b, 2 * b + 1)
        expected_remainders = (b - 1, 0, 1, b - 1, 0, 1)
        for group, a, expected_q, expected_r in zip(
            GROUPS, dividends, EXPECTED_Q, expected_remainders
        ):
            yield group, a, b, expected_q, expected_r


def main():
    rows = list(vectors())
    counts = Counter(group for group, *_ in rows)
    if counts != Counter({g: 16 for g in GROUPS}):
        raise AssertionError(f"wrong group distribution: {counts}")
    seen = set()
    lines = []
    for group, a, b, expected_q, expected_r in rows:
        if a < 0 or b <= 0 or (a, b) in seen:
            raise AssertionError("invalid or duplicate input")
        seen.add((a, b))
        q, r = divmod(a, b)
        if (q, r) != (expected_q, expected_r):
            raise AssertionError(f"quotient boundary mismatch: {group}")
        if a != q * b + r or not 0 <= r < b:
            raise AssertionError("Euclidean identity mismatch")
        if len(str(a)) != 512 or len(str(b)) != 512:
            raise AssertionError("operand is not exactly 512 digits")
        lines.append("\t".join((group, str(a), str(b), str(q), str(r))))
    if len(lines) != 96 or len(seen) != 96:
        raise AssertionError("unexpected case count")
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="ascii")
    if OUTPUT.read_text(encoding="ascii").splitlines() != lines:
        raise AssertionError("TSV readback mismatch")
    print("Python-int quotient512: 96/96 unique, six groups x16, "
          "all A/B exactly 512 digits, 0 divergences")


if __name__ == "__main__":
    main()
