#!/usr/bin/env python3
"""Python-int oracle for sparse/max-limb quotient and radix-edge divisor QA.

No Pascal algorithm/fixtures are read. Values are constructed arithmetically,
then checked with Python's independent arbitrary-precision divmod.
"""
from collections import Counter
from pathlib import Path

BASE = 10**9
GROUPS = (
    "ZERO_GAPS", "MAX_RUN", "CROSS_SPAN",
    "BELOW_POWER", "ABOVE_POWER", "R_NEAR_POWER",
)
OUTPUT = Path(__file__).with_name("bigint_divmod_radix_limb_lattice.tsv")


def quotient(group, index):
    count = 11 + index
    digits = []
    for j in range(count):
        if group in ("ZERO_GAPS", "BELOW_POWER"):
            digit = BASE - 1 if j % 3 == 0 else 0
        elif group in ("MAX_RUN", "ABOVE_POWER"):
            digit = 0 if j % 5 == 2 else BASE - 1
        else:
            digit = (0, BASE - 1, 1, BASE - 1)[j % 4]
        digits.append(digit)
    digits[-1] = BASE - 1 if index % 2 else 1
    return sum(d * BASE**j for j, d in enumerate(digits))


def vectors():
    for i in range(8):
        power = BASE ** (3 + i % 6)
        q = {name: quotient(name, i) for name in GROUPS}
        items = (
            ("ZERO_GAPS", power + BASE + 1, (power + BASE + 1)//2),
            ("MAX_RUN", power - BASE + 7, power - BASE + 6),
            ("CROSS_SPAN", power + BASE**2 - 1, 0),
            ("BELOW_POWER", power - 1, power - 2),
            ("ABOVE_POWER", power + 1, 0),
            ("R_NEAR_POWER", power + BASE**2 - 1,
             power + BASE**2 - 1 - BASE),
        )
        for group, b, r in items:
            yield group, b * q[group] + r, b, q[group], r


def main():
    rows = list(vectors())
    counts = Counter(group for group, *_ in rows)
    if counts != Counter({name: 8 for name in GROUPS}):
        raise AssertionError(f"wrong group distribution: {counts}")
    seen = set()
    lines = []
    for group, a, b, expected_q, expected_r in rows:
        if a < 0 or b <= 0 or not (0 <= expected_r < b) or (a, b) in seen:
            raise AssertionError("invalid or duplicated inputs")
        seen.add((a, b))
        q, r = divmod(a, b)
        if (q, r) != (expected_q, expected_r) or a != q*b+r:
            raise AssertionError(f"Python-int expectation mismatch: {group}")
        digits = []
        n = q
        while n:
            n, d = divmod(n, BASE)
            digits.append(d)
        if not (11 <= len(digits) <= 18 and 0 in digits[:-1] and
                BASE - 1 in digits[:-1] and len(str(a)) < 300):
            raise AssertionError(f"quotient-limb lattice contract: {group}")
        lines.append("\t".join(map(str, (group, a, b, q, r))))
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="ascii")
    if OUTPUT.read_text(encoding="ascii").splitlines() != lines:
        raise AssertionError("readback mismatch")
    print("Python-int radix limb lattice: 48/48 unique, six groups x8, "
          "quotient 11..18 limbs with interior zero/max limbs; "
          "max A<300 decimal digits, 0 divergences")


if __name__ == "__main__":
    main()
