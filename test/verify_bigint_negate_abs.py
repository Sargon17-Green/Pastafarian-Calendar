#!/usr/bin/env python3
"""Independent Python arbitrary-precision integer oracle for Pascal unary QA."""
import csv
import re
from collections import Counter
from pathlib import Path

DECIMAL = re.compile(r"(?:0|-?[1-9][0-9]*)\\Z".replace("\\\\Z", "\\Z"))
CATEGORIES = {"ZERO": 1, "TIE": 20, "SMALL": 16,
              "RADIX_LO": 28, "RADIX_HI": 28, "LONG": 3}
TIES = {1, 2, 7, 10, 12345, 987654321, 10**9, 10**18, 10**27, 10**72}


def main():
    path = Path(__file__).with_name("bigint_negate_abs_vectors.tsv")
    with path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))
    assert len(rows) == 96, f"expected 96 rows, got {len(rows)}"
    counts = Counter()
    seen = set()
    radix_below, radix_above = set(), set()
    ties = {}
    max_digits = 0
    for index, row in enumerate(rows, 1):
        assert len(row) == 4, f"row {index}: expected four fields"
        category, source, negated, absolute = row
        assert category in CATEGORIES, f"row {index}: category"
        assert all(DECIMAL.fullmatch(x) for x in row[1:]), f"row {index}: decimal syntax"
        assert source not in seen, f"row {index}: duplicate source"
        seen.add(source)
        value = int(source)
        assert negated == str(-value), f"row {index}: negation oracle"
        assert absolute == str(abs(value)), f"row {index}: absolute oracle"
        magnitude = abs(value)
        max_digits = max(max_digits, len(source.lstrip("-")))
        if category == "ZERO":
            assert value == 0
        elif category == "TIE":
            assert magnitude in TIES and value != 0
            ties.setdefault(magnitude, set()).add((value > 0) - (value < 0))
        elif category == "SMALL":
            assert 25 <= magnitude <= 32
        elif category in ("RADIX_LO", "RADIX_HI"):
            matches = [k for k in range(1, 29)
                       if magnitude == 10**(9*k) + (-1 if category == "RADIX_LO" else 1)]
            assert len(matches) == 1, f"row {index}: radix boundary"
            k = matches[0]
            sign = (value > 0) - (value < 0)
            assert sign == (1 if (k % 2 == 1) == (category == "RADIX_LO") else -1)
            (radix_below if category == "RADIX_LO" else radix_above).add(k)
        else:
            assert category == "LONG"
            assert 255 <= len(source.lstrip("-")) <= 256
        counts[category] += 1
    assert counts == Counter(CATEGORIES), counts
    assert all(signs == {-1, 1} for signs in ties.values()) and len(ties) == 10
    assert radix_below == radix_above == set(range(1, 29))
    assert max_digits == 256, max_digits
    print("Python-int BigNegate/BigAbs oracle: 96/96 unique; "
          "20 signed ties; 28 lower+28 upper radix edges; 256 digits; "
          "planned Pascal assertions=2304; 0 divergences")


if __name__ == "__main__":
    main()
