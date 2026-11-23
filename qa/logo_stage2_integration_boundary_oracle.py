#!/usr/bin/env python3
"""Independent host-only integration boundary mathematics for PC-BRANCH-LOGO-IDO.

No imports of project code, UCBLogo, normative reference or fixtures.
This is NOT a Native gate and does not validate the Logo implementation.
"""
from collections import Counter

M_PRODUCTION = 2**127 - 1


def reference_walk(base: int, first: int, step: int, n: int):
    """Explicitly materialize digits; enumerate candidate rejection for small base."""
    width = 1
    space = base
    while space < n:
        width += 1
        space *= base
    digit = first
    weight = 1
    initial = 1
    for _ in range(width):
        initial += (digit - 1) * weight
        digit += step
        if digit < 1:
            digit = base
        elif digit > base:
            digit = 1
        weight *= base
    accepted_end = (space // n) * n
    candidate = initial
    rejected = 0
    for _ in range(space):
        if candidate <= accepted_end:
            return width, initial, 1 + ((candidate - 1) % n), rejected
        candidate += step
        if candidate < 1:
            candidate = space
        elif candidate > space:
            candidate = 1
        rejected += 1
    raise AssertionError("full candidate cycle without acceptance")


def shortcut(base: int, first: int, step: int, n: int):
    """Independent closed-form digit indexing + reverse Horner arithmetic."""
    width, space = 1, base
    while n > space:
        width += 1
        space *= base
    accumulator = 0
    for j in range(width - 1, -1, -1):
        digit = (first - 1 + step * j) % base + 1
        accumulator = accumulator * base + (digit - 1)
    initial = accumulator + 1
    limit = space - (space % n)
    if initial > limit:
        rank = 1 if step == 1 else n
    else:
        rank = ((initial - 1) % n) + 1
    return width, initial, rank


def main():
    count = 0
    rejected = 0
    widths = Counter()
    for base in range(2, 12):
        candidates = range(1, base**3 + 1)
        for n in list(candidates) + [base**3 + 1, base**4]:
            for first in range(1, base + 1):
                for step in (-1, 1):
                    width, initial, expected, rejects = reference_walk(base, first, step, n)
                    actual = shortcut(base, first, step, n)
                    assert actual == (width, initial, expected), (
                        base, first, step, n, (width, initial, expected), actual
                    )
                    assert 1 <= expected <= n
                    count += 1
                    widths[width] += 1
                    if rejects:
                        rejected += 1
    # Production-sized boundary vectors: pure arithmetic/shape checks only.
    # Huge rejection walks are intentionally not attempted; no differential label.
    m = M_PRODUCTION
    boundary_ns = [m, m + 1, m*m, m*m + 1, m**31 + 1,
                   m**32, m**32 + 1, m**63 + 1, m**64, m**64 + 1]
    big_count = 0
    for n in boundary_ns:
        for first in (1, 2, m-1, m):
            for step in (-1, 1):
                k, w, rank = shortcut(m, first, step, n)
                assert m**(k-1) < n <= m**k or k == 1 and n <= m
                assert 1 <= w <= m**k and 1 <= rank <= n
                big_count += 1
    print("PROJECT_ID=PC-BRANCH-LOGO-IDO")
    print("SCOPE=HOST_MATH_ONLY; NO_NATIVE; NO_CANONICAL_PROMOTION")
    print(f"FINITE_DIFFERENTIAL_CASES={count}")
    print(f"FINITE_REJECTED_INITIAL_CASES={rejected}")
    print("FINITE_WIDTH_COUNTS=" + ",".join(f"k{k}:{widths[k]}" for k in sorted(widths)))
    print(f"PRODUCTION_M_BOUNDARY_SHAPE_CASES={big_count}")
    print("LOGO_IDO_INTEGRATION_HOST_MATH=PASS")


if __name__ == "__main__":
    main()
