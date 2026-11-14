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
    assert sign in ("0", "1", "2"), sign  # Codesh: 0=zero, 1=positive, 2=negative
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
    binomials = [(50,20), (4300,40), (1000,33), (5000,45)]
    divisors = [1,2,3,7,97,100,101,123,1001]
    expected_keys = {"MONTH_WAYS_4244_45", "MONTH_UNRANK_FIRST_4244_45", "WEAVE_4_4", "WEAVE_4_5_6", "WEAVE_4_5_6_4", "MUL_LARGE", "MUL_SQUARE", "MUL_NEGATIVE", "MUL_UNIT", "MUL_ZERO"}
    expected_keys.update(f"BINOM_{n}_{k}" for n,k in binomials)
    expected_keys.update(f"QUOTIENT_5000_45_BY_{d}" for d in divisors)
    assert set(result) == expected_keys, (set(result), expected_keys)
    for n,k in binomials:
        assert parse_bigint(result[f"BINOM_{n}_{k}"]) == math.comb(n,k), (n,k)
    big_number = math.comb(5000,45)
    for divisor in divisors:
        assert parse_bigint(result[f"QUOTIENT_5000_45_BY_{divisor}"]) == big_number // divisor, divisor
    assert parse_bigint(result["MONTH_WAYS_4244_45"]) == month_ways(4244, 45)
    values = {"MUL_LARGE": math.comb(5000,45)*math.comb(3000,35),
        "MUL_SQUARE": math.comb(5000,45)**2,
        "MUL_NEGATIVE": -123456789*math.comb(5000,45),
        "MUL_UNIT": math.comb(5000,45), "MUL_ZERO": 0}
    for name,expected in values.items():
        assert parse_bigint(result[name]) == expected, (name, expected)

    # Native historical fixtures of the Codesh-specific constrained weave,
    # deliberately NOT assumed to equal ordinary multinomial coefficients.
    for key,expected in {"WEAVE_4_4":20, "WEAVE_4_5_6":21594, "WEAVE_4_5_6_4":7342209}.items():
        assert parse_bigint(result[key]) == expected, (key,expected)
    months = [int(x) for x in result["MONTH_UNRANK_FIRST_4244_45"].split(",")]
    assert len(months) == 45, len(months)
    assert sum(months) == 4244, sum(months)
    assert all(4 <= x <= 123 for x in months), months
    print(f"CODESH_NATIVE_COMBINATORICS_PASS binomialCases=4 smallDivisorCases=9 monthCountCases=1 unrankCases=1 weaveRegressionCases=3 multiplicationCases=5 monthCount={len(months)} monthSum={sum(months)}")


if __name__ == "__main__":
    main()
