#!/usr/bin/env python3
"""Independent Python-int edge oracle for zero and unit-divisor BigInt modulo.

Branch-only QA. The generated vectors are not historical source-patch evidence.
Each row is (category, A, positive D, floor(A/D), Euclidean remainder).
"""
import csv
from collections import Counter
from pathlib import Path

EXPONENTS = (9, 18, 45, 72, 99, 126, 144, 162, 198, 234, 270, 306)
CATEGORIES = ("UNIT_POS", "UNIT_NEG", "ZERO_BELOW", "ZERO_ABOVE")
OUTPUT = Path(__file__).with_name("bigint_regular_mod_zero_unit.tsv")


def create_cases():
    cases = []
    for exponent in EXPONENTS:
        radix = 10 ** exponent
        definitions = (
            ("UNIT_POS", radix + 1, 1),
            ("UNIT_NEG", -(radix + 1), 1),
            ("ZERO_BELOW", 0, radix - 1),
            ("ZERO_ABOVE", 0, radix + 1),
        )
        for category, dividend, divisor in definitions:
            quotient, remainder = divmod(dividend, divisor)
            assert divisor > 0
            assert dividend == quotient * divisor + remainder
            assert 0 <= remainder < divisor
            cases.append((category, dividend, divisor, quotient, remainder))
    return cases


def main():
    cases = create_cases()
    assert len(EXPONENTS) == 12 and len(set(EXPONENTS)) == 12
    assert all(exponent % 9 == 0 for exponent in EXPONENTS)
    assert len(cases) == 48
    with OUTPUT.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerows(cases)
    with OUTPUT.open("r", encoding="utf-8", newline="") as handle:
        persisted = list(csv.reader(handle, delimiter="\t"))
    assert len(persisted) == 48
    pairs = set()
    counts = Counter()
    for row in persisted:
        assert len(row) == 5
        category, a_s, d_s, q_s, r_s = row
        a, d, q, r = map(int, (a_s, d_s, q_s, r_s))
        assert (a, d) not in pairs
        pairs.add((a, d))
        assert (q, r) == divmod(a, d)
        assert a == q * d + r and 0 <= r < d
        if category == "UNIT_POS":
            assert d == 1 and a > 0 and q == a and r == 0
        elif category == "UNIT_NEG":
            assert d == 1 and a < 0 and q == a and r == 0
        elif category in ("ZERO_BELOW", "ZERO_ABOVE"):
            assert a == q == r == 0 and d > 1
        else:
            raise AssertionError("unexpected category")
        counts[category] += 1
    assert counts == Counter({category: 12 for category in CATEGORIES})
    print("Python-int zero/unit oracle: 48/48 unique; four groups x12; "
          "0 divergences; Pascal assertions planned 384.")


if __name__ == "__main__":
    main()
