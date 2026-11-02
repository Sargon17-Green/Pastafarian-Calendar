#!/usr/bin/env python3
"""Bounded independent constructive witness for Chapel month-weaving state growth.

No production code is imported, no exhaustive production-size enumeration is attempted.
Run: python3 test/weaving_reachability_oracle.py
"""
from itertools import product
from math import prod

SOURCE_SHA = "e3e5f2e1ef38207d59005ce8bababe4c83910bfa"
RUN_ID = 41409195449
MONTH_LENGTHS = (
    115, 108, 119, 109, 106, 81, 115, 114, 117, 120,
    98, 52, 81, 97, 121, 97, 115, 96, 107, 61,
    106, 115, 119, 39, 84, 103, 115, 107, 55, 119,
    97, 50, 122, 110, 81, 54, 101, 83, 88, 40,
    25, 77, 98, 122, 105,
)
EXPECTED_LOWER = 3991035906815373105625242639483993147254913074560959521179023099422632606433280000000000
EXPECTED_UPPER = 11830849694409842033801632685168653766464341042891367133822803767174129299698483200000000


def construct_and_replay(lengths, residual):
    """Open months in order, consume extras without closing; verify each transition."""
    assert len(lengths) == len(residual)
    assert all(n >= 2 and 1 <= r < n for n, r in zip(lengths, residual))
    prefix = list(range(1, len(lengths) + 1))
    for month, (n, r) in enumerate(zip(lengths, residual), 1):
        prefix.extend([month] * (n - r - 1))

    remaining = list(lengths)
    opened, closed = 0, 0
    for month in prefix:
        pos = month - 1
        assert remaining[pos] > 0
        if remaining[pos] == lengths[pos]:
            assert month == opened + 1, "Opening order violation"
            opened = month
        if remaining[pos] == 1:
            assert month == closed + 1, "Closing order violation"
            closed = month
        remaining[pos] -= 1

    assert tuple(remaining) == tuple(residual)
    assert opened == len(lengths) and closed == 0
    return tuple(remaining), opened, closed


def main():
    assert len(MONTH_LENGTHS) == 45
    assert sum(MONTH_LENGTHS) == 4244
    assert prod(n - 1 for n in MONTH_LENGTHS) == EXPECTED_LOWER
    assert prod(n + 1 for n in MONTH_LENGTHS) == EXPECTED_UPPER

    checked = 0
    for small in ((2, 2), (2, 3, 2), (3, 4, 5, 3), (2, 3, 4, 2, 3)):
        distinct = set()
        for residual in product(*(range(1, n) for n in small)):
            distinct.add(construct_and_replay(small, residual))
            checked += 1
        assert len(distinct) == prod(n - 1 for n in small)

    for residual in (
        tuple(1 for _ in MONTH_LENGTHS),
        tuple(n - 1 for n in MONTH_LENGTHS),
        tuple(1 if i % 2 == 0 else n - 1
              for i, n in enumerate(MONTH_LENGTHS)),
    ):
        construct_and_replay(MONTH_LENGTHS, residual)
        checked += 1

    assert checked == 66
    print("WEAVING_REACHABILITY_FIXTURE_SHA=" + SOURCE_SHA)
    print("WEAVING_REACHABILITY_FIXTURE_RUN=" + str(RUN_ID))
    print("WEAVING_REACHABILITY_WITNESS_CHECKS=" + str(checked))
    print("WEAVING_REACHABILITY_LOWER_BOUND=" + str(EXPECTED_LOWER))
    print("WEAVING_REACHABILITY_UPPER_BOUND=" + str(EXPECTED_UPPER))
    print("WEAVING_REACHABILITY_RESULT=PASS")


if __name__ == "__main__":
    main()
