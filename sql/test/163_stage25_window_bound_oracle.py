#!/usr/bin/env python3
"""Independent bounded-window index oracle. Synthetic, not PostgreSQL/Native.

Checks the two-direction sentinel walk against a bisect-based oracle.
No canonical fixtures, normative SQL, or production code are imported.
"""
from bisect import bisect_left, bisect_right
from random import Random

SEED = 251621
TRIALS = 1200

def oracle_window(gates, calculation_day):
    lo, hi = calculation_day - 5778, calculation_day + 5778
    return bisect_right(gates, lo) - 2, bisect_left(gates, hi) + 1

def walked_window(gates, calculation_day, origin):
    lower, upper = calculation_day - 5778, calculation_day + 5778
    visited = {}
    for direction, limit in ((1, upper), (-1, lower)):
        at = origin
        sentinel_done = False
        while True:
            if not 0 <= at < len(gates):
                raise AssertionError("Synthetic gate domain too small")
            visited[at] = gates[at]
            if sentinel_done:
                break
            crossed = (gates[at] >= limit if direction == 1
                       else gates[at] <= limit)
            at += direction
            sentinel_done = crossed
    eligible_lower = [i for i, d in visited.items() if d <= lower]
    eligible_upper = [i for i, d in visited.items() if d >= upper]
    if not eligible_lower or not eligible_upper:
        raise AssertionError("Sentinel walk did not span both limits")
    start, end = max(eligible_lower) - 1, min(eligible_upper) + 1
    return start, end, tuple(gates[start:end+1])

def main():
    rng = Random(SEED)
    passed = 0
    for trial in range(TRIALS):
        origin = 350
        gaps = [rng.randint(42, 963) for _ in range(700)]
        gates = [0] * 701
        for i in range(origin + 1, len(gates)):
            gates[i] = gates[i-1] + gaps[i-1]
        for i in range(origin - 1, -1, -1):
            gates[i] = gates[i+1] - gaps[i]
        pivot = rng.randint(origin-135, origin+135)
        mode = trial % 4
        calc = (gates[pivot] if mode == 0 else
                gates[pivot] - 1 if mode == 1 else
                gates[pivot] + 1 if mode == 2 else
                gates[pivot] + rng.randint(0, gaps[pivot]-1))
        expected = oracle_window(gates, calc)
        got_start, got_end, actual = walked_window(gates, calc, origin)
        assert (got_start, got_end) == expected, (trial, expected, (got_start,got_end))
        assert actual == tuple(gates[expected[0]:expected[1]+1])
        assert 15 <= len(actual) <= 280
        passed += 1
    print(f"SLICE25_WINDOW_INDEX_STATIC={passed}/{TRIALS} PASS")
    print("CLASSIFICATION=SYNTHETIC_INDEX_ORACLE_NOT_NATIVE_NOT_DIFFERENTIAL")

if __name__ == "__main__":
    main()
