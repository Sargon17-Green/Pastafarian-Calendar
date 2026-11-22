#!/usr/bin/env python3
"""Hebrew Scroll seal 32: independent, bounded small-shape weaving oracle.

The authority is the Hebrew Scroll first- and last-occurrence ordering rule.
No import of candidate Fortran, pinned Python, or candidate fixtures is allowed.
This oracle is deliberately bounded to small shapes: it does NOT certify the
44-month, 4,399-day Foundation weaving or any five-field date.
"""
from __future__ import annotations

import argparse
from functools import lru_cache
from itertools import product

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SCROLL_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7"
MAX_SMALL_DAYS = 16
MAX_STATES = 250_000


def ordered_endpoints(word: tuple[int, ...], colors: int) -> bool:
    """Independent whole-word predicate; no DP state or prefix logic."""
    if len(word) == 0 or set(word) != set(range(1, colors + 1)):
        return False
    first = [word.index(i) for i in range(1, colors + 1)]
    last = [len(word) - 1 - word[::-1].index(i) for i in range(1, colors + 1)]
    return first == sorted(first) and last == sorted(last)


def exhaustive_words(lengths: tuple[int, ...]) -> list[tuple[int, ...]]:
    """Brute-force baseline: generate EVERY multiset word, filter at the end."""
    counts = list(lengths)
    out: list[tuple[int, ...]] = []
    stack: list[int] = []
    def enumerate_all() -> None:
        if len(stack) == sum(lengths):
            word = tuple(stack)
            if ordered_endpoints(word, len(lengths)):
                out.append(word)
            return
        for i, remaining in enumerate(counts):
            if remaining:
                counts[i] -= 1
                stack.append(i + 1)
                enumerate_all()
                stack.pop()
                counts[i] += 1
    enumerate_all()
    return out


class SmallWeavingOracle:
    """Exact memoized legal-prefix recurrence, rank indexed from zero."""

    def __init__(self, lengths: tuple[int, ...]):
        if not lengths or any(type(n) is not int or n < 1 for n in lengths):
            raise ValueError("expected positive integer multiplicities")
        if sum(lengths) > MAX_SMALL_DAYS:
            raise ValueError("small oracle bounded: cannot evaluate full-year target")
        self.lengths = lengths
        self.colors = len(lengths)
        self.visits = 0

        @lru_cache(maxsize=None)
        def suffixes(remaining: tuple[int, ...], opened: int) -> int:
            self.visits += 1
            if self.visits > MAX_STATES:
                raise RuntimeError("bounded state budget exceeded")
            if not any(remaining):
                return int(opened == self.colors)
            return sum(suffixes(nxt, seen) for _, nxt, seen in self.children(remaining, opened))
        self.suffixes = suffixes

    def children(self, remaining: tuple[int, ...], opened: int):
        # Unseen colors must appear for the first time in ascending order.
        for color in range(1, min(self.colors, opened + 1) + 1):
            if remaining[color - 1] == 0:
                continue
            nxt = list(remaining)
            nxt[color - 1] -= 1
            seen = max(opened, color)
            # If color i is exhausted, all smaller colors must already
            # have been exhausted: this is equivalent to ordered LASTs.
            if any(nxt[i] == 0 and any(nxt[:i]) for i in range(seen)):
                continue
            yield color, tuple(nxt), seen

    def count(self) -> int:
        return self.suffixes(self.lengths, 0)

    def unrank(self, rank: int) -> tuple[int, ...]:
        total = self.count()
        if type(rank) is not int or not 0 <= rank < total:
            raise ValueError("rank outside legal weaving family")
        remaining, opened = self.lengths, 0
        result: list[int] = []
        while any(remaining):
            for color, nxt, seen in self.children(remaining, opened):
                size = self.suffixes(nxt, seen)
                if rank >= size:
                    rank -= size
                else:
                    result.append(color)
                    remaining, opened = nxt, seen
                    break
            else:
                raise AssertionError("legal lexicographic branch missing")
        if rank != 0 or opened != self.colors:
            raise AssertionError("nonzero residual lexicographic rank")
        return tuple(result)


def self_test() -> tuple[int, int, int]:
    shapes = ranks = assertions = 0
    for colors in range(1, 5):
        for lengths in product((1, 2, 3), repeat=colors):
            if sum(lengths) > 10:
                continue
            brute = exhaustive_words(lengths)
            oracle = SmallWeavingOracle(lengths)
            assert oracle.count() == len(brute), (lengths, "count")
            shapes += 1
            assertions += 1
            for rank, expected in enumerate(brute):
                actual = oracle.unrank(rank)
                assert actual == expected, (lengths, rank, expected, actual)
                assert ordered_endpoints(actual, colors)
                ranks += 1
                assertions += 2
            if len(brute) > 2:
                for rank in (0, 1, len(brute) // 2, len(brute) - 2, len(brute) - 1):
                    assert oracle.unrank(rank) == brute[rank]
                    assertions += 1
            for invalid in (-1, len(brute)):
                try:
                    oracle.unrank(invalid)
                except ValueError:
                    assertions += 1
                else:
                    raise AssertionError((lengths, "invalid rank accepted"))
    assert SmallWeavingOracle((2, 2)).count() == 2
    assertions += 1
    for invalid_shape in ((), (0,), (1, -1), (1.5,), (17,)):
        try:
            SmallWeavingOracle(invalid_shape)
        except ValueError:
            assertions += 1
        else:
            raise AssertionError("accepted invalid shape")
    return shapes, ranks, assertions


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--lengths", type=str, help="comma-separated small multiplicities")
    p.add_argument("--rank", type=int, default=0, help="zero-based lexicographic rank")
    a = p.parse_args()
    if a.self_test:
        shapes, ranks, assertions = self_test()
        print(f"STAGE01_SCROLL_WEAVING_SMALL_SHAPES={shapes}")
        print(f"STAGE01_SCROLL_WEAVING_SMALL_RANKS={ranks}")
        print(f"STAGE01_SCROLL_WEAVING_SMALL_ASSERTIONS={assertions}")
        print("STAGE01_SCROLL_WEAVING_SMALL_BRUTE_DIFFERENTIAL=PASS")
        print("STAGE01_SCROLL_WEAVING_SMALL_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    if a.lengths:
        oracle = SmallWeavingOracle(tuple(map(int, a.lengths.split(","))))
        print("COUNT=" + str(oracle.count()))
        print("WORD=" + ",".join(map(str, oracle.unrank(a.rank))))
    if not a.self_test and not a.lengths:
        p.error("specify --self-test or --lengths")


if __name__ == "__main__":
    main()
