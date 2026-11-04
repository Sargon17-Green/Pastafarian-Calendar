#!/usr/bin/env python3
"""Independent closed-form Slice21 oracle; no SQL imports or production code."""
import argparse
from itertools import product
from math import comb


def count(total: int, slots: int, lower: int = 4, upper: int = 123) -> int:
    if slots < 0 or lower > upper:
        return 0
    if slots == 0:
        return int(total == 0)
    excess = total - slots * lower
    window = upper - lower + 1
    if excess < 0 or excess > slots * (upper - lower):
        return 0
    answer = 0
    for j in range(min(slots, excess // window) + 1):
        rest = excess - j * window
        term = comb(slots, j) * comb(rest + slots - 1, slots - 1)
        answer += (-1 if j % 2 else 1) * term
    return answer


def unrank(total: int, slots: int, rank1: int, lower: int = 4, upper: int = 123) -> tuple[int, ...] | None:
    space = count(total, slots, lower, upper)
    if rank1 < 1 or rank1 > space or slots < 1:
        return None
    out = []
    rem = total
    for left in range(slots, 0, -1):
        # Independent cumulative-count binary search; no DP or database oracle.
        def prefix(x: int) -> int:
            return sum(count(rem - v, left - 1, lower, upper)
                       for v in range(lower, x + 1))
        low, high = lower, upper
        while low < high:
            mid = (low + high) // 2
            if prefix(mid) >= rank1:
                high = mid
            else:
                low = mid + 1
        selected = low
        rank1 -= prefix(selected - 1)
        out.append(selected)
        rem -= selected
    assert rem == 0 and rank1 == 1
    return tuple(out)


def cases():
    # Exactly 50 deterministic, independently computed fixtures.
    domain = (252, 253, 259, 492, 493, 740, 984, 1230, 2460, 5778)
    pairs = []
    for total in domain:
        min_k = (total + 122) // 123
        max_k = min(47, total // 4)
        for k in sorted({min_k, max_k, (min_k + max_k) // 2}):
            if count(total, k):
                pairs.append((total, k))
    selection = []
    for d, k in pairs:
        n = count(d, k)
        for r in sorted({1, (n + 1) // 2, n}):
            selection.append((d, k, r))
    # Interleave over boundary classes rather than simply first 50.
    chosen = selection[::2] + selection[1::2]
    assert len(chosen) >= 50
    return chosen[:50]


def self_test():
    checked = 0
    # Direct exhaustive enumeration of all 4+16+64+256=340 tuples.
    for slots in range(1, 5):
        by_total = {}
        for values in product(range(4, 8), repeat=slots):
            by_total.setdefault(sum(values), []).append(values)
        for total in range(slots * 4, slots * 7 + 1):
            expected = sorted(by_total.get(total, []))
            assert count(total, slots, 4, 7) == len(expected)
            for rank, row in enumerate(expected, 1):
                assert unrank(total, slots, rank, 4, 7) == row
                checked += 1
    assert checked == 340
    for d in (252, 253, 492, 2460, 5778):
        k = (d + 122) // 123
        assert count(d, k) >= 1
        assert count(d, 47) >= 1
    fixtures = cases()
    assert len(fixtures) == 50
    for d, k, r in fixtures:
        a = unrank(d, k, r)
        assert a is not None and len(a) == k and sum(a) == d
        assert all(4 <= x <= 123 for x in a)
    print(f"slice21-oracle=PASS exhaustive-tuples={checked} full-boundaries=5 fixtures={len(fixtures)}")


def emit_sql():
    print("-- Slice21 independent Python-generated exact ranked-composition fixtures.")
    print("CREATE TEMP TABLE slice21_goldens(days integer,slots integer,rank1 numeric,expected integer[]);")
    for d, k, r in cases():
        numbers = ",".join(str(x) for x in unrank(d, k, r))
        print(f"INSERT INTO slice21_goldens VALUES ({d},{k},{r},ARRAY[{numbers}]::integer[]);")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--self-test", action="store_true")
    group.add_argument("--emit-sql", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    else:
        emit_sql()
