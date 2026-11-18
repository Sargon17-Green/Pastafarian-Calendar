#!/usr/bin/env python3
"""Independent Python-int oracle for 96 long-decimal BigFromDecimal cases.

Inputs: nine-column TSV. Checks: input identity, signed value, absolute,
negation, successor, predecessor, sign, base-1e9 limb count. No Pascal
implementation code is imported and no historical source provenance is claimed.
"""
import csv
from collections import Counter
from pathlib import Path

SOURCE = Path(__file__).with_name("bigint_decimal_long_vectors.tsv")
COUNTS = {"ZERO": 12, "SMALL": 16, "RADIX": 24, "LONG": 32, "LEADING": 12}
EXPECTED_CASES = 96
PASCAL_CHECKS = 96 * 14


def input_cases():
    for i in range(12):
        yield "ZERO", ("-" if i % 2 else "") + "0" * (i + 1)
    for n in list(range(-8, 0)) + list(range(1, 9)):
        yield "SMALL", ("-" if n < 0 else "") + "000" + str(abs(n))
    for k in (9, 18, 37, 73):
        for sign in (-1, 1):
            for delta in (-1, 0, 1):
                yield "RADIX", str(sign * (10**k + delta))
    for i in range(32):
        size = (64, 127, 256, 511)[i // 8]
        digits = str(1 + (i * 7 + 3) % 9)
        digits += "".join(str((i * 13 + j * j + 7 * j) % 10)
                          for j in range(1, size))
        if i % 4 == 0:
            digits = digits[:-12] + "0" * 12
        yield "LONG", ("-" if i % 2 else "") + digits
    for i in range(12):
        n = 10**(9 + (i % 6) * 13) + (i % 3 - 1)
        yield "LEADING", ("-" if i % 2 else "") + "0" * (35 + i * 4) + str(n)


def oracle(group, raw):
    value = int(raw)
    magnitude = abs(value)
    sign = (value > 0) - (value < 0)
    limbs = (len(str(magnitude)) + 8) // 9 if value else 0
    return [group, raw, str(value), str(magnitude), str(-value),
            str(value + 1), str(value - 1), str(sign), str(limbs)]


def main():
    with SOURCE.open(encoding="utf-8", newline="") as handle:
        actual = list(csv.reader(handle, delimiter="\t"))
    expected = [oracle(group, raw) for group, raw in input_cases()]
    if len(expected) != EXPECTED_CASES or len(actual) != EXPECTED_CASES:
        raise AssertionError(f"cases mismatch: {len(actual)}")
    if Counter(row[0] for row in expected) != Counter(COUNTS):
        raise AssertionError("category distribution mismatch")
    if len(set(row[1] for row in expected)) != EXPECTED_CASES:
        raise AssertionError("duplicate input literal")
    for i, (got, want) in enumerate(zip(actual, expected), 1):
        if got != want:
            raise AssertionError(f"row {i}: got={got!r}; want={want!r}")
    if max(len(row[1]) for row in expected) > 512:
        raise AssertionError("unbounded decimal input")
    print(f"Python-int long decimal oracle: {len(actual)}/{EXPECTED_CASES} "
          f"independent rows, distribution={COUNTS}, "
          f"planned Pascal checks={PASCAL_CHECKS}, 0 divergences")


if __name__ == "__main__":
    main()
