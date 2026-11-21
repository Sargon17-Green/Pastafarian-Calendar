#!/usr/bin/env python3
"""Independent signed sub-divisor Euclidean remainder oracle (Stage1 QA only).

Creates fresh cases arithmetically, without importing Pascal algorithms or
historical source-patch fixtures. Contract: D>0, 0<|A|<D;
A = floor(A/D)*D + (A mod D), with 0 <= remainder < D.
"""
import csv
from collections import Counter
from pathlib import Path

BASE = 10**9
OUT = Path(__file__).with_name("bigint_regular_mod_subdivisor.tsv")
EXPECTED = {
    "POS_TINY": 12, "NEG_TINY": 12,
    "POS_NEAR": 12, "NEG_NEAR": 12,
}

def generate():
    rows = []
    for family in ("TINY", "NEAR"):
        for i in range(12):
            power = BASE ** (i + 2)
            divisor = power - (i + 3) if family == "TINY" else power + (i + 3)
            magnitude = i + 1 if family == "TINY" else divisor - (i + 2)
            assert 0 < magnitude < divisor
            for sign, prefix in ((1, "POS"), (-1, "NEG")):
                dividend = sign * magnitude
                q, r = divmod(dividend, divisor)
                assert dividend == q * divisor + r and 0 < r < divisor
                assert q == (0 if sign > 0 else -1)
                assert r == (magnitude if sign > 0 else divisor - magnitude)
                rows.append((prefix + "_" + family, dividend, divisor, q, r))
    return rows

def main():
    rows = generate()
    seen = set()
    tally = Counter()
    with OUT.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerows(rows)
    with OUT.open("r", encoding="utf-8", newline="") as handle:
        persisted = list(csv.reader(handle, delimiter="\t"))
    assert len(persisted) == 48
    for fields in persisted:
        assert len(fields) == 5
        cat, a_s, d_s, q_s, r_s = fields
        a, d, q, r = map(int, (a_s, d_s, q_s, r_s))
        assert (a, d) not in seen
        seen.add((a, d))
        assert 0 < abs(a) < d
        assert (q, r) == divmod(a, d)
        assert a == q * d + r and 0 < r < d
        assert q == (-1 if a < 0 else 0)
        assert r == (d - abs(a) if a < 0 else a)
        tally[cat] += 1
    assert dict(tally) == EXPECTED, (tally, EXPECTED)
    print("Python-int sub-divisor oracle: 48/48 unique; "
          "24 signed mirror pairs; four categories; zero divergences.")
    print("Pascal assertions planned: 48 x 8 + 6 invalid-domain = 390.")

if __name__ == "__main__":
    main()
