#!/usr/bin/env python3
"""SQL+தமிழ் Slice 18 independent separator-combination oracle.
No production SQL imports and no DP recurrence are used here.
"""
from __future__ import annotations
import argparse
from itertools import combinations
from math import comb


def partitions(g: int, k: int, required: int | None = None) -> list[tuple[int, ...]]:
    if not 1 <= k <= g or (required is not None and not 1 <= required < g):
        return []
    result = []
    for cuts in combinations(range(1, g), k - 1):
        if required is not None and required not in cuts:
            continue
        edges = (0,) + cuts + (g,)
        result.append(tuple(b - a for a, b in zip(edges, edges[1:])))
    return sorted(result)


def enumerate_small():
    for g in range(6, 10):
        for k in range(6, g + 1):
            for required in (None,) + tuple(range(1, g)):
                for rank, parts in enumerate(partitions(g, k, required), start=1):
                    yield g, k, required, rank, parts


def self_test() -> int:
    expectations = [
        (6, 6, None, 1),
        (7, 6, None, 6), (7, 6, 2, 5),
        (8, 6, None, 21), (8, 6, 3, 15),
        (9, 7, None, 28), (9, 7, 3, 21),
    ]
    checks = 0
    for g, k, required, count in expectations:
        assert len(partitions(g, k, required)) == count, (g, k, required)
        checks += 1
    for g in range(6, 13):
        for k in range(6, min(9, g) + 1):
            full = partitions(g, k)
            assert len(full) == comb(g - 1, k - 1)
            checks += 1
            for required in range(1, g):
                subset = partitions(g, k, required)
                assert subset == [p for p in full if
                                  required in tuple(sum(p[:j]) for j in range(1, k))]
                checks += 1
    all_rows = list(enumerate_small())
    assert len(all_rows) == len(set(all_rows))
    assert all(len(parts) == k and sum(parts) == g and min(parts) > 0
               for g, k, _, _, parts in all_rows)
    checks += 2
    print(f"SEPARATOR_ORACLE_PASS checks={checks} golden_rows={len(all_rows)}")
    return checks


def emit_sql() -> None:
    print("CREATE TEMP TABLE stage02_partition_goldens (")
    print("g integer NOT NULL,k integer NOT NULL,r integer,q integer NOT NULL,")
    print("expected integer[] NOT NULL,")
    print("PRIMARY KEY (g,k,r,q));")
    # PostgreSQL UNIQUE treats NULL as distinct; table is only a read-only fixture.
    for g, k, required, rank, parts in enumerate_small():
        r = "NULL" if required is None else str(required)
        arr = ",".join(map(str, parts))
        print(f"INSERT INTO stage02_partition_goldens VALUES "
              f"({g},{k},{r},{rank},ARRAY[{arr}]::integer[]);")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--emit-sql", action="store_true")
    args = parser.parse_args()
    self_test()
    if args.emit_sql:
        emit_sql()
