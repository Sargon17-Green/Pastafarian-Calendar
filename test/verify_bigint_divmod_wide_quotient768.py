#!/usr/bin/env python3
"""Independent decimal/Python-int oracle for wide positive division.

48 deterministic pairs in six groups of eight. Inputs A and B have
exactly 768 and 384 decimal digits; quotient Q has exactly 384 digits.
No Pascal radix, implementation, or fixtures are used to generate cases.
"""
from collections import Counter
from hashlib import sha256
from pathlib import Path

GROUPS = (
    "SPARSE_EXACT", "SPARSE_ONE", "DENSE_EXACT",
    "DENSE_MAX_REM", "NINES_ONE", "ALTERNATING_HALF",
)
OUTPUT = Path(__file__).with_name("bigint_divmod_wide_quotient768.tsv")
TEN383 = 10**383


def suffix(label, index):
    digits = "".join(
        f"{int.from_bytes(sha256(f'wide768-v1:{label}:{index}:{j}'.encode('ascii')).digest(), 'big') % (10**77):077d}"
        for j in range(5)
    )[:383]
    return int(digits)


def vectors():
    for index in range(8):
        b = 4 * TEN383 + suffix("divisor", index)
        dense_q = 3 * TEN383 + suffix("quotient", index)
        pairs = (
            (3 * TEN383, 0),
            (3 * TEN383 + 1, 1),
            (dense_q, 0),
            (dense_q, b - 1),
            (4 * TEN383 - 1, 1),
            (3 * TEN383 + int(("90" * 192)[:383]), b // 2),
        )
        for group, (q, r) in zip(GROUPS, pairs):
            yield group, b * q + r, b, q, r


def main():
    rows = list(vectors())
    if Counter(g for g, *_ in rows) != Counter({g: 8 for g in GROUPS}):
        raise AssertionError("wrong group cardinalities")
    if len(rows) != 48:
        raise AssertionError("wrong total cardinality")
    seen = set()
    lines = []
    for group, a, b, q_expected, r_expected in rows:
        if b <= 0 or a < 0 or (a, b) in seen:
            raise AssertionError("nonpositive/duplicate input")
        seen.add((a, b))
        q, r = divmod(a, b)
        if (q, r) != (q_expected, r_expected):
            raise AssertionError(f"analytical expectation mismatch: {group}")
        if a != b * q + r or not (0 <= r < b):
            raise AssertionError("Euclidean invariant failed")
        if (len(str(a)), len(str(b)), len(str(q))) != (768, 384, 384):
            raise AssertionError(f"operand/quotient width mismatch: {group}")
        lines.append("\t".join(map(str, (group, a, b, q, r))))
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="ascii")
    if OUTPUT.read_text(encoding="ascii").splitlines() != lines:
        raise AssertionError("TSV readback mismatch")
    print("Python-int wide quotient768: 48/48 unique, six groups x8, "
          "A=768 B=384 Q=384 digits, 0 divergences")


if __name__ == "__main__":
    main()
