#!/usr/bin/env python3
"""Exact independent mathematical checks of bounded Codesh Native raw-limb output."""
import math
import pathlib
import sys

BASE = 10_000


def parse_bigint(row):
    sign, count_text, limbs_text = row.split("\t")
    count = int(count_text)
    limbs = [int(x) for x in limbs_text.split(",")]
    assert count == len(limbs) and count >= 1, (count, limbs)
    assert all(0 <= x < BASE for x in limbs), limbs
    assert sign in ("0", "1", "-1"), sign
    magnitude = sum(x * BASE**i for i, x in enumerate(limbs))
    return 0 if sign == "0" else (1 if sign == "1" else -1) * magnitude


def month_ways(total, count):
    # Count vectors with count entries in [4,123], by inclusion-exclusion.
    shifted = total - 4 * count
    value = 0
    for j in range(count + 1):
        x = shifted - 120 * j + count - 1
        if x < count - 1:
            continue
        value += ((-1)**j) * math.comb(count, j) * math.comb(x, count - 1)
    return value


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: check_native_combinatorics.py PROBE_OUTPUT_TSV")
    lines = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
    result = {}
    for line in lines:
        name, value = line.split("\t", 1)
        assert name not in result, f"duplicate key {name}"
        result[name] = value
    expected_keys = {"BINOM_50_20", "BINOM_4300_40", "MONTH_WAYS_4244_45", "MONTH_UNRANK_FIRST_4244_45"}
    assert set(result) == expected_keys, (set(result), expected_keys)
    assert parse_bigint(result["BINOM_50_20"]) == math.comb(50, 20)
    assert parse_bigint(result["BINOM_4300_40"]) == math.comb(4300, 40)
    assert parse_bigint(result["MONTH_WAYS_4244_45"]) == month_ways(4244, 45)
    months = [int(x) for x in result["MONTH_UNRANK_FIRST_4244_45"].split(",")]
    assert len(months) == 45, len(months)
    assert sum(months) == 4244, sum(months)
    assert all(4 <= x <= 123 for x in months), months
    print(f"CODESH_NATIVE_COMBINATORICS_PASS binomialCases=2 monthCountCases=1 unrankCases=1 monthCount={len(months)} monthSum={sum(months)}")


if __name__ == "__main__":
    main()
