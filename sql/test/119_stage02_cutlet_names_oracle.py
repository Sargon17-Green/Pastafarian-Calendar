#!/usr/bin/env python3
"""Slice19 independent bounded enumeration oracle; no production factoradics.

For each 1 <= k <= n <= 7, explicitly sort permutations, then select
one-based ranks. It deliberately never imports/calls production code.
"""
import argparse
import itertools


def oracle_cases():
    for n in range(1, 8):
        for k in range(1, n + 1):
            ordered = sorted(itertools.permutations(range(1, n + 1), k))
            size = len(ordered)
            ranks = sorted({1, 2, (size + 1) // 2, size // 3 + 1, size})
            for rank in ranks:
                if 1 <= rank <= size:
                    yield n, k, rank, ordered[rank - 1]


def emit_sql():
    print("-- Slice19 Python itertools independent oracle; ranked ascending, n<=7.")
    print("CREATE TEMP TABLE slice19_goldens (n integer, k integer, rank1 numeric, expected integer[]);")
    for n, k, rank, expected in oracle_cases():
        literal = ",".join(map(str, expected))
        print(f"INSERT INTO slice19_goldens VALUES ({n},{k},{rank},ARRAY[{literal}]::integer[]);")


def self_test():
    pairs = 0
    total = 0
    for n in range(1, 8):
        for k in range(1, n + 1):
            ordered = sorted(itertools.permutations(range(1, n + 1), k))
            assert ordered[0] == tuple(range(1, k + 1))
            assert ordered[-1] == tuple(range(n, n - k, -1))
            assert len(ordered) == len(set(ordered))
            assert all(a < b for a, b in zip(ordered, ordered[1:]))
            pairs += 1
            total += len(ordered)
    cases = list(oracle_cases())
    assert len(cases) >= 100
    assert len(set((n, k, rank) for n, k, rank, _ in cases)) == len(cases)
    print(f"oracle selftest PASS pairs={pairs} permutations={total} goldens={len(cases)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--emit-sql", action="store_true")
    group.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.emit_sql:
        emit_sql()
    else:
        self_test()
