#!/usr/bin/env python3
"""Independent Python-int oracle: six near-512-digit positive division groups."""
from collections import Counter
from pathlib import Path

COUNTS = {name: 16 for name in (
    "ZERO_SMALL", "LESS_THAN", "RADIX_EDGE", "EXACT", "MAX_REM", "DENSE"
)}
OUT = Path(__file__).with_name("bigint_floor_div_positive_boundary512.tsv")


def dense_decimal(first, count, shift):
    return int(str(first) + "".join(str((j * 7 + shift) % 10) for j in range(count)))


def vectors():
    for i in range(16):
        divisor = 10**511 + i * 17 + 2
        yield "ZERO_SMALL", (0 if i == 0 else i * 13 + 1), divisor
    for i in range(16):
        divisor = 10**511 + i * 101 + 71
        yield "LESS_THAN", divisor - 1, divisor
    for i in range(16):
        divisor = 10 ** (9 * (41 + i)) + (-7, -1, 1, 7)[i % 4]
        quotient = 1 + i % 4
        remainder = 0 if i % 2 == 0 else divisor - 1
        yield "RADIX_EDGE", quotient * divisor + remainder, divisor
    for i in range(16):
        divisor = 10**500 + i * 1301 + 17
        quotient = 10 ** (i % 8) + 3
        yield "EXACT", quotient * divisor, divisor
    for i in range(16):
        divisor = 10**500 - i * 107 - 17
        quotient = 10 ** (i % 9) + 3
        yield "MAX_REM", quotient * divisor + divisor - 1, divisor
    for i in range(16):
        if i < 8:
            divisor = dense_decimal(8, 511, i * 3)
            dividend = divisor - i - 2
        else:
            divisor = dense_decimal(7, 509, i * 3)
            quotient = i - 6
            remainder = i + 1 if i % 2 == 0 else divisor - i - 1
            dividend = divisor * quotient + remainder
        yield "DENSE", dividend, divisor


def main():
    cases = list(vectors())
    counts = Counter(name for name, _, _ in cases)
    if len(cases) != 96 or counts != Counter(COUNTS):
        raise AssertionError(f"wrong groups: {counts}")
    seen = set()
    lines = []
    max_a = max_b = exact_a = exact_b = 0
    for name, dividend, divisor in cases:
        if dividend < 0 or divisor <= 0 or (dividend, divisor) in seen:
            raise AssertionError("invalid signed/zero/duplicate operands")
        seen.add((dividend, divisor))
        quotient, remainder = divmod(dividend, divisor)
        if dividend != quotient * divisor + remainder or not 0 <= remainder < divisor:
            raise AssertionError("Python-int Euclidean identity failed")
        a, b, q, r = map(str, (dividend, divisor, quotient, remainder))
        if max(map(len, (a, b, q, r))) > 512:
            raise AssertionError("512 decimal digit limit exceeded")
        max_a, max_b = max(max_a, len(a)), max(max_b, len(b))
        exact_a += len(a) == 512
        exact_b += len(b) == 512
        lines.append("\t".join((name, a, b, q, r)))
    if len(seen) != 96 or max_a != 512 or max_b != 512:
        raise AssertionError("cardinality or full 512-digit edge missing")
    if exact_a < 16 or exact_b < 16:
        raise AssertionError("insufficient 512-digit coverage")
    OUT.write_text("\n".join(lines) + "\n", encoding="ascii")
    print("Python-int boundary512: 96/96 unique, six groups x16, "
          f"max A={max_a}, max B={max_b}, exact512 A={exact_a}, "
          f"exact512 B={exact_b}, 0 divergences")


if __name__ == "__main__":
    main()
