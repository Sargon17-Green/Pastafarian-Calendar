#!/usr/bin/env python3
"""SQL+Tamil Slice22: independent bounded combinatorial feasibility/preflight.

Not production and not a PostgreSQL test.  The brute oracle constructs all
multiset words, filters the two global ordering rules, and knows nothing about
suffix-factor DP.  The latter is tested against the oracle, never used to
create the oracle's expected sequences.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from itertools import accumulate
from math import comb
from time import monotonic
import tracemalloc
import sys
sys.set_int_max_str_digits(0)  # The exact root legitimately has >4300 digits.


def exhaustive_words(lengths: tuple[int, ...]) -> list[tuple[int, ...]]:
    """Literal independent all-word enumerator, then filter both global orders."""
    k = len(lengths)
    remaining = list(lengths)
    complete = []
    path = []
    def visit():
        if not any(remaining):
            complete.append(tuple(path))
            return
        for j in range(k):
            if remaining[j]:
                remaining[j] -= 1
                path.append(j + 1)
                visit()
                path.pop()
                remaining[j] += 1
    visit()
    expected = tuple(range(1, k + 1))
    good = []
    for word in complete:
        first = tuple(sorted(expected, key=word.index))
        last = tuple(sorted(expected, key=lambda j: len(word) - 1 - word[::-1].index(j)))
        if first == expected and last == expected:
            good.append(word)
    return sorted(good)


def factors(lengths: tuple[int, ...]) -> list[list[int]]:
    """Exact integer suffix-factor Pascal prefix DP (no SQL/reference calls)."""
    if not lengths or any(x < 2 for x in lengths):
        raise ValueError("This mathematical model requires lengths >= 2")
    k = len(lengths)
    maximum_tail = sum(lengths) - k
    result: list[list[int]] = [[] for _ in range(k + 1)]
    result[k] = [1] * (maximum_tail + 1)
    for a in range(k, 0, -1):
        h = lengths[a - 1]
        maximum_tail -= h - 1
        prev = result[a]
        row = []
        prefix = 0
        binomial = 1
        for t in range(maximum_tail + 1):
            prefix += prev[t + h - 1] * binomial
            row.append(prefix)
            # C(t+h-1,h-2) from C(t+h-2,h-2), exactly.
            numer = binomial * (t + h - 1)
            assert numer % (t + 1) == 0
            binomial = numer // (t + 1)
        result[a - 1] = row
    assert maximum_tail == 0
    return result


def suffix_count(lengths: tuple[int, ...], prefix: tuple[int, ...], dp: list[list[int]]) -> int:
    k = len(lengths)
    if any(j < 1 or j > k for j in prefix):
        return 0
    used = Counter(prefix)
    if any(used[i] > lengths[i - 1] for i in range(1, k + 1)):
        return 0
    order = sorted(used.keys(), key=prefix.index)
    if order != list(range(1, len(order) + 1)):
        return 0
    opened = len(order)
    rem = [lengths[i - 1] - used[i] for i in range(1, k + 1)]
    closed = 0
    while closed < opened and rem[closed] == 0:
        closed += 1
    if any(rem[i] == 0 for i in range(closed, opened)):
        return 0
    if not prefix and opened != 0:
        return 0
    # A valid prefix cannot have closed its month out of increasing last order.
    # All closed IDs are initial segment 1..closed, and all others have rem > 0.
    tail = 0
    active = 1
    for i in range(closed, opened):
        tail += rem[i]
        active *= comb(tail - 1, rem[i] - 1)
    if tail >= len(dp[opened]):
        return 0
    return active * dp[opened][tail]


def check_small() -> tuple[int, int, int]:
    vectors = ((2,2),(2,3),(3,3),(2,2,2),(3,2,2),(2,2,3),(3,3,3),(2,3,3),(3,2,3))
    total_words = 0
    total_prefixes = 0
    all_rank_checks = 0
    for lengths in vectors:
        words = exhaustive_words(lengths)
        dp = factors(lengths)
        assert len(words) == dp[0][0], (lengths, len(words), dp[0][0])
        histogram = Counter()
        for word in words:
            for p in range(len(word) + 1):
                histogram[word[:p]] += 1
        for prefix, actual in histogram.items():
            predicted = suffix_count(lengths, prefix, dp)
            assert actual == predicted, (lengths, prefix, actual, predicted)
            total_prefixes += 1
        # For each rank use suffix blocks in increasing IDs, not the oracle word.
        for rank, word in enumerate(words, 1):
            result = []
            r = rank
            while len(result) < sum(lengths):
                for candidate in range(1, len(lengths) + 1):
                    n = suffix_count(lengths, tuple(result + [candidate]), dp)
                    if r > n:
                        r -= n
                    elif n > 0:
                        result.append(candidate)
                        break
                else:
                    raise AssertionError((lengths, rank, "no candidate"))
            assert tuple(result) == word and r == 1, (lengths, rank, tuple(result), word)
            all_rank_checks += 1
        total_words += len(words)
    return total_words, total_prefixes, all_rank_checks


def boundary_probe(lengths: tuple[int, ...]) -> dict:
    tracemalloc.start()
    start = monotonic()
    dp = factors(lengths)
    elapsed = monotonic() - start
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    root = dp[0][0]
    return {
        "k": len(lengths), "D": sum(lengths),
        "cells": sum(map(len, dp)), "total_count_digits": len(str(root)),
        "elapsed_s": round(elapsed, 4), "peak_traced_mib": round(peak / (1024*1024), 3),
        "root_positive": root > 0,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--self-test', action='store_true')
    p.add_argument('--bench', action='store_true')
    args = p.parse_args()
    if not (args.self_test or args.bench):
        p.error('select --self-test or --bench')
    if args.self_test:
        words, prefixes, rank_checks = check_small()
        print(f"PASS small-vectors=9 exact-words={words} exact-prefixes={prefixes} rank-roundtrips={rank_checks}")
    if args.bench:
        for shape in ((120,) + (123,)*46, (4,)*46 + (68,), (123,)*20, (52,)*47):
            print(boundary_probe(shape), flush=True)


if __name__ == '__main__':
    main()
