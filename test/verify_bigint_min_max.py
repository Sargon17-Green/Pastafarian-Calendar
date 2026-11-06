#!/usr/bin/env python3
"""Independent integer oracle for BigMin and BigMax selection, 96 signed pairs."""
import csv
import re
from collections import Counter
from pathlib import Path

CATEGORIES = ("EQUAL", "POSITIVE", "NEGATIVE", "OPPOSITE", "ZERO", "RADIX")
DECIMAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")

def check():
    path = Path(__file__).with_name("bigint_min_max_vectors.tsv")
    with path.open(encoding="utf-8", newline="") as source:
        rows = list(csv.reader(source, delimiter="\t"))
    assert len(rows) == 96, f"expected 96 rows, got {len(rows)}"
    counts = Counter()
    seen = set()
    bounds = set()
    longest = 0
    zero_pairs = 0
    selections = set()
    negative_pairs = positive_pairs = 0
    for line, fields in enumerate(rows, 1):
        assert len(fields) == 5, f"line {line}: expected five fields"
        category, sa, sb, expected_min, expected_max = fields
        assert category in CATEGORIES, f"line {line}: unknown category"
        assert all(DECIMAL.fullmatch(s) for s in fields[1:]), f"line {line}: decimal syntax"
        assert (sa, sb) not in seen, f"line {line}: duplicated pair"
        seen.add((sa, sb))
        a, b, wanted_min, wanted_max = map(int, fields[1:])
        # Python integers form an oracle independent of Pascal's base-10^9 limbs.
        assert (wanted_min, wanted_max) == (min(a, b), max(a, b)), (
            f"line {line}: independent signed-order oracle mismatch")
        if category == "EQUAL":
            assert a == b
        elif category == "POSITIVE":
            assert a > 0 and b > 0
        elif category == "NEGATIVE":
            assert a < 0 and b < 0
        elif category == "OPPOSITE":
            assert a * b < 0
        elif category == "ZERO":
            assert (a == 0) != (b == 0)
        else:
            assert category == "RADIX"
            assert any(
                abs(abs(x) - 10 ** (9 * k)) <= 1
                for x in (a, b) for k in range(1, 29)
            ) or max(len(sa.lstrip("-")), len(sb.lstrip("-"))) == 256
        counts[category] += 1
        longest = max(longest, len(sa.lstrip("-")), len(sb.lstrip("-")))
        zero_pairs += int(a == 0 or b == 0)
        negative_pairs += int(a < 0 or b < 0)
        positive_pairs += int(a > 0 or b > 0)
        selections.add((a > b) - (a < b))
        for k in range(1, 29):
            radix = 10 ** (9 * k)
            if any(abs(abs(x) - radix) <= 1 for x in (a, b)):
                bounds.add(k)
    assert counts == Counter({name: 16 for name in CATEGORIES}), counts
    assert len(seen) == 96
    assert longest == 256, longest
    assert zero_pairs >= 16
    assert negative_pairs > 0 and positive_pairs > 0
    assert bounds == set(range(1, 29)), bounds
    assert selections == {-1, 0, 1}, selections
    print("Python-int BigMin/BigMax oracle: 96/96 unique, 6x16, "
          f"radix=28, max=256 digits, zero-pairs={zero_pairs}, "
          "selection=-1/0/1; expected Pascal checks=960; 0 divergences")

if __name__ == "__main__":
    check()
