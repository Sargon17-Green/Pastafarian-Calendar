#!/usr/bin/env python3
"""Independent signed base-10^9 limb oracle for BigToDecimal, Stage 1.

This derives expected text using Python arbitrary-precision integers, not
Pascal BigToDecimal or BigFromDecimal. Emits deterministic bounded TSV for FPC.
"""
from collections import Counter
from pathlib import Path

BASE = 10**9
COUNTS = {"SMALL": 16, "RADIX": 24, "SPARSE": 24, "DENSE": 32}
SOURCE = Path(__file__).with_name("bigint_to_decimal_vectors.tsv")


def limbs_of(number):
    digits = []
    while number:
        number, remainder = divmod(number, BASE)
        digits.append(remainder)
    return digits


def cases():
    for n in range(1, 9):
        for sign in (-1, 1):
            yield "SMALL", sign, limbs_of(n)
    for k in (1, 2, 3, 7):
        for sign in (-1, 1):
            for delta in (-1, 0, 1):
                yield "RADIX", sign, limbs_of(BASE**k + delta)
    for k in (4, 8, 12, 20, 35, 55):
        for sign in (-1, 1):
            for tail in (1, BASE - 1):
                yield "SPARSE", sign, limbs_of(BASE**k + tail)
    for length in (7, 14, 28, 56):
        for variant in range(8):
            digits = [
                BASE - 1 if (i + variant) % 4 == 0
                else (i * 7919 + variant * 104729) % BASE
                for i in range(length)
            ]
            digits[0] = variant + 1
            if digits[-1] == 0:
                digits[-1] = 1
            yield "DENSE", (-1 if variant % 2 else 1), digits


def main():
    case_list = list(cases())
    if len(case_list) != 96 or Counter(g for g, _, _ in case_list) != Counter(COUNTS):
        raise AssertionError("bad case count/category distribution")
    rows = []
    seen = set()
    largest = 0
    for group, sign, digits in case_list:
        if sign not in (-1, 1) or not digits or not (0 < digits[-1] < BASE):
            raise AssertionError("noncanonical signed limb representation")
        if any(not (0 <= digit < BASE) for digit in digits):
            raise AssertionError("limb out of range")
        magnitude = sum(digit * (BASE ** i) for i, digit in enumerate(digits))
        value = sign * magnitude
        if value in seen:
            raise AssertionError("duplicate numeric vector")
        seen.add(value)
        decimal = str(value)
        largest = max(largest, len(decimal))
        if len(decimal) > 512:
            raise AssertionError("unbounded decimal output")
        rows.append("\t".join((group, str(sign), ",".join(map(str, digits)),
                               decimal, str(magnitude), str(-value),
                               str(len(digits)))))
    if len(seen) != 96:
        raise AssertionError("not all vectors unique")
    SOURCE.write_text("\n".join(rows) + "\n", encoding="ascii")
    print(f"Python-int BigToDecimal oracle: 96/96 unique, categories={COUNTS}, "
          f"max decimal length={largest}, planned Pascal checks=1152, "
          "0 divergences")


if __name__ == "__main__":
    main()
