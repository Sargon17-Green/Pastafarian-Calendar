#!/usr/bin/env python3
"""SQL+தமிழ் Stage2 Slice23 independent rank feasibility proof.

Produces no implementation and no PG claim. Complete small-domain enumeration
using itertools.permutations is an independent witness to candidate-block unranking.
This script belongs to the SQL+தமிழ் branch only.
"""
from __future__ import annotations

from itertools import permutations
from math import perm, factorial


def unrank_distinct(n: int, k: int, rank1: int) -> tuple[int, ...]:
    """Exact candidate-block unranking to be compared with brute enumeration."""
    if not (1 <= k <= n and 1 <= rank1 <= perm(n, k)):
        raise ValueError("rank outside legal distinct-sequence domain")
    remaining = list(range(1, n + 1))
    result: list[int] = []
    r = rank1 - 1
    for position in range(k):
        block = perm(n - position - 1, k - position - 1)
        candidate_index, r = divmod(r, block)
        if not (0 <= candidate_index < len(remaining)):
            raise AssertionError("candidate outside remaining set")
        result.append(remaining.pop(candidate_index))
    if r != 0:
        raise AssertionError("unconsumed rank")
    return tuple(result)


def verify_small() -> tuple[int, int]:
    shape_count = 0
    compared = 0
    for n in (3, 4, 5, 6):
        for k in range(1, n + 1):
            brute = list(permutations(range(1, n + 1), k))
            assert len(brute) == perm(n, k)
            assert brute == sorted(brute)
            for rank1, expected in enumerate(brute, 1):
                assert unrank_distinct(n, k, rank1) == expected, (n, k, rank1)
                compared += 1
            shape_count += 1
    return shape_count, compared


def verify_boundary() -> tuple[int, int, int]:
    checks = 0
    for k in (1, 2, 3, 17, 47):
        count = perm(47, k)
        assert count > 0
        ranks = {1, (count + 1) // 2, count}
        for rank1 in sorted(ranks):
            seq = unrank_distinct(47, k, rank1)
            assert len(seq) == k and len(set(seq)) == k
            assert all(1 <= x <= 47 for x in seq)
            if rank1 == 1:
                assert seq == tuple(range(1, k + 1))
            if rank1 == count:
                assert seq == tuple(range(47, 47 - k, -1))
            checks += 1
    assert perm(47, 47) == factorial(47)
    digits = len(str(factorial(47)))
    return checks, digits, factorial(47)


def main() -> None:
    shapes, compared = verify_small()
    checks, digits, fact = verify_boundary()
    print(f"PASS small_shapes={shapes} brute_full_sequences={compared} "+
          f"boundary_checks={checks} k47_count_digits={digits} "+
          f"k47_count={fact} model=Python-not-PostgreSQL")


if __name__ == "__main__":
    main()
