#!/usr/bin/env python3
"""Independent integer-arithmetic oracle for proposed Stage02 work-count slice.

Standard library only. Does not import Pascal code or fixtures from other branches.
Generates a deterministic UTF-8 TSV of 96 distinct directed day pairs.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
from pathlib import Path

FOUNDATION = -15055671
HEADER = ('group', 'calculation_day', 'target_day', 'action', 'target',
          'distance', 'connection', 'direction')


def day_count(day: int) -> int:
    if day < FOUNDATION:
        return 2 * (FOUNDATION - day)
    return 2 * (day - FOUNDATION) + 1


def oracle(calculation: int, target: int) -> tuple[int, int, int, int, int]:
    a = day_count(calculation)
    t = day_count(target)
    return a, t, abs(target - calculation) + 1, a + t, (1 if target < calculation else 2 if target == calculation else 3)


def pairs() -> list[tuple[str, int, int]]:
    f = FOUNDATION
    g: list[tuple[str, int, int]] = []
    # Equal days: both sides of origin and zero; no reliance on random sampling.
    equal = [f + k for k in (-128, -17, -8, -3, -2, -1, 0, 1, 2, 3, 8, 17, 128, 0 - f, 2**63, -(2**63))]
    g.extend(('EQUAL', x, x) for x in equal)
    # Adjacent transitions straddling and away from foundation.
    g.extend(('ADJACENT', f + k, f + k + (1 if i % 2 == 0 else -1))
             for i, k in enumerate(range(-8, 8)))
    # Strict order in both directions, differing spans.
    g.extend(('FORWARD', f - 40 + i, f + 41 + 2*i) for i in range(16))
    g.extend(('REVERSE', f + 41 + 2*i, f - 40 + i) for i in range(16))
    bounds = [-(2**63)-1, -(2**63), -(2**63)+1, -1, 0, 1, (2**63)-2, (2**63)-1, 2**63, (2**63)+1,
              -(2**127), -(2**127)+1, (2**127)-1, 2**127, -(2**255), 2**255]
    g.extend(('INTEGER_BOUNDARY', x, f) for x in bounds)
    powers = [10**128, 10**256, 10**512, 2**1024]
    for i in range(16):
        p = powers[i // 4]
        a = (-p if i % 2 else p) + i
        b = (p if i % 3 else -p) - (i + 1)
        g.append(('HUGE', a, b))
    assert len(g) == 96
    assert len({(a,b) for _,a,b in g}) == 96
    assert {name: sum(z[0] == name for z in g) for name in
            ('EQUAL', 'ADJACENT', 'FORWARD', 'REVERSE', 'INTEGER_BOUNDARY', 'HUGE')} == {
            name: 16 for name in ('EQUAL', 'ADJACENT', 'FORWARD', 'REVERSE', 'INTEGER_BOUNDARY', 'HUGE')}
    return g


def table() -> bytes:
    out = ['\t'.join(HEADER)]
    for group, c, t in pairs():
        expected = oracle(c, t)
        # Metamorphic, algebraic and range checks independent of Pascal output.
        a, b, distance, connection, direction = expected
        assert a >= 1 and b >= 1 and distance >= 1
        assert connection == a + b
        assert distance - 1 == abs(c - t)
        assert direction in (1,2,3)
        assert (direction == 1) == (t < c)
        assert (direction == 2) == (t == c)
        assert (direction == 3) == (t > c)
        if c == FOUNDATION: assert a == 1
        if t == FOUNDATION: assert b == 1
        out.append('\t'.join(str(x) for x in (group, c, t, *expected)))
    assert day_count(FOUNDATION) == 1
    assert all(day_count(FOUNDATION - k) == 2*k and
               day_count(FOUNDATION + k) == 2*k + 1 for k in range(1,513))
    return ('\n'.join(out) + '\n').encode('utf-8')


def validate_existing(data: bytes) -> None:
    expected = table()
    if data != expected:
        raise SystemExit('FAIL: TSV differs from independent canonical oracle')
    rows = data.decode('utf-8', errors='strict').splitlines()
    assert len(rows) == 97 and rows[0].split('\t') == list(HEADER)
    assert all(len(row.split('\t')) == 8 for row in rows[1:])


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--emit', type=Path, help='write deterministic UTF-8 canonical TSV')
    group.add_argument('--check', type=Path, help='compare existing TSV bytes with oracle')
    group.add_argument('--self-test', action='store_true', help='validate 96 vectors and 512 boundary identities')
    args = ap.parse_args()
    expected = table()
    if args.emit is not None:
        args.emit.write_bytes(expected)
        validate_existing(args.emit.read_bytes())
    elif args.check is not None:
        validate_existing(args.check.read_bytes())
    else:
        validate_existing(expected)
    print('PASS rows=96 groups=6 vectors_per_group=16 boundary_identities=1024')
    print('TSV_SHA256=' + sha256(expected).hexdigest())


if __name__ == '__main__':
    main()
