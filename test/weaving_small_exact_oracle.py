#!/usr/bin/env python3
"""Independent small-N oracle for FIFO month weaving. Standard library only."""
from functools import lru_cache
from itertools import product
from math import comb, factorial, prod


def brute_words(lengths):
    left = list(lengths)
    at = [[] for _ in left]
    accepted = []

    def rec(word):
        if not any(left):
            if all(at[i][0] < at[i+1][0] and at[i][-1] < at[i+1][-1]
                   for i in range(len(left)-1)):
                accepted.append(tuple(word))
            return
        for i in range(len(left)):
            if left[i]:
                left[i] -= 1
                at[i].append(len(word))
                word.append(i+1)
                rec(word)
                word.pop()
                at[i].pop()
                left[i] += 1
    rec([])
    return accepted


def poset_oracle(lengths):
    groups = [tuple((i, j) for j in range(n))
              for i, n in enumerate(lengths, 1)]
    nodes = [x for group in groups for x in group]
    lookup = {node: k for k, node in enumerate(nodes)}
    prerequisite = [0] * len(nodes)

    def edge(a, b):
        prerequisite[lookup[b]] |= 1 << lookup[a]
    for group in groups:
        for a, b in zip(group, group[1:]):
            edge(a, b)
    for a, b in zip(groups, groups[1:]):
        edge(a[0], b[0])
        edge(a[-1], b[-1])
    full = (1 << len(nodes)) - 1

    def choices(mask):
        return [(nodes[k][0], k) for k, pred in enumerate(prerequisite)
                if not (mask >> k & 1) and mask & pred == pred]

    @lru_cache(None)
    def count(mask):
        if mask == full:
            return 1
        return sum(count(mask | 1 << k) for _, k in choices(mask))

    def unrank(r):
        if not 0 <= r < count(0):
            raise ValueError("rank out of bounds")
        mask, word = 0, []
        while mask != full:
            for symbol, k in sorted(choices(mask)):
                group_count = count(mask | 1 << k)
                if r < group_count:
                    word.append(symbol)
                    mask |= 1 << k
                    break
                r -= group_count
            else:
                raise AssertionError("no legal successor")
        return tuple(word)

    def rank(word):
        mask, r = 0, 0
        for symbol in word:
            for candidate, k in sorted(choices(mask)):
                if candidate < symbol:
                    r += count(mask | 1 << k)
                elif candidate == symbol:
                    mask |= 1 << k
                    break
            else:
                raise ValueError("illegal prefix")
        if mask != full:
            raise ValueError("truncated word")
        return r
    return count(0), rank, unrank, count.cache_info().currsize


def main():
    cases = [p for k in range(1, 5) for p in product(range(1, 5), repeat=k)
             if sum(p) <= 8]
    cases.extend(((2,2,2,2,2), (2,3,2,2), (3,2,3,2), (2,2,3,3),
                  (3,3,2,2), (4,3,2), (2,4,3), (1,2,1,3), (3,1,2,2)))
    cases = list(dict.fromkeys(cases))
    roundtrips = cases_checked = biggest = max_states = 0
    for lengths in cases:
        assert 0 < sum(lengths) <= 10
        accepted = brute_words(lengths)
        total, rank, unrank, states = poset_oracle(lengths)
        assert total == len(accepted) == len(set(accepted)), lengths
        assert total <= factorial(sum(lengths)) // prod(factorial(x) for x in lengths)
        if len(lengths) == 2:
            assert total == comb(sum(lengths)-2, lengths[0]-1)
        if lengths == (2,) * len(lengths):
            m = len(lengths)
            assert total == comb(2*m, m) // (m+1)
        for i, word in enumerate(accepted):
            assert unrank(i) == word
            assert rank(word) == i
            roundtrips += 2
        for invalid in (-1, total):
            try:
                unrank(invalid)
            except ValueError:
                pass
            else:
                raise AssertionError((lengths, invalid))
        cases_checked += 1
        biggest = max(biggest, total)
        max_states = max(max_states, states)
    assert cases_checked == 137 and roundtrips == 1982
    print(f"WEAVING_SMALL_ORACLE_CASES={cases_checked}")
    print(f"WEAVING_SMALL_ORACLE_RANK_ROUNDTRIPS={roundtrips}")
    print(f"WEAVING_SMALL_ORACLE_LARGEST_COUNT={biggest}")
    print(f"WEAVING_SMALL_ORACLE_MAX_DP_STATES={max_states}")
    print("WEAVING_SMALL_ORACLE_RESULT=PASS")


if __name__ == "__main__":
    main()
