#!/usr/bin/env python3
"""Independent Stage56 Phase B mathematical discovery, not production/native acceptance."""
from __future__ import annotations
from itertools import product
from math import comb
from time import perf_counter


def suffix_count(remaining: tuple[int, ...], opened: int) -> int:
    """Rank-independent insertion DP. Labels 1..m, opened is last seen label in prefix.

    All remaining multiplicities must be positive from first nonzero to m;
    zeros are permitted only as an initial prefix of closed labels.
    """
    first = next((i for i, n in enumerate(remaining) if n), len(remaining))
    if first == len(remaining):
        return 1
    assert all(n > 0 for n in remaining[first:])
    if not 0 <= opened <= len(remaining):
        raise ValueError('opened')
    prev = [1]  # position 0 for the empty word, with one empty sequence
    old_n = 0
    for index in range(first, len(remaining)):
        n = remaining[index]
        total_prev = sum(prev)
        constrained = (index + 1) > opened + 1
        current = [0] * (old_n + 2)  # current[q] for q=1..old_n+1
        if n == 1:
            current[old_n + 1] = total_prev
        else:
            running = 0
            for gap in range(old_n + 1):
                if old_n:
                    running += prev[gap] if gap < len(prev) else 0  # prefix of first-position distribution
                allowed = running if constrained else total_prev
                # previous empty word (old_n=0): all one-symbol words allowed
                if constrained and old_n == 0:
                    allowed = 0
                current[gap + 1] = allowed * comb(old_n - gap + n - 2, n - 2)
        prev = current
        old_n += n
    return sum(prev)


def words(counts: tuple[int, ...]):
    m = len(counts)
    remaining = list(counts)
    out = []
    def dfs(opened: int, closed: int):
        if not any(remaining):
            yield tuple(out)
            return
        for j in range(m):
            if remaining[j] == 0 or j + 1 > opened + 1:
                continue
            # last occurrences must be in increasing order
            if remaining[j] == 1 and any(remaining[i] for i in range(j)):
                continue
            remaining[j] -= 1
            out.append(j + 1)
            yield from dfs(max(opened, j + 1), closed + (remaining[j] == 0))
            out.pop()
            remaining[j] += 1
    yield from dfs(0, 0)


def prefix_count(counts: tuple[int, ...], prefix: tuple[int,...]):
    remaining = list(counts)
    opened = 0
    for j in prefix:
        if not 1 <= j <= len(counts) or j > opened + 1 or remaining[j-1] == 0:
            return 0
        if remaining[j-1] == 1 and any(remaining[:j-1]):
            return 0
        remaining[j-1] -= 1
        opened = max(opened,j)
    return suffix_count(tuple(remaining),opened)


def test():
    count_cases = prefix_cases = word_cases = 0
    for m in range(1,5):
        for counts in product(range(1,4),repeat=m):
            oracle=list(words(counts))
            assert oracle == sorted(oracle)
            got=suffix_count(counts,0)
            assert got == len(oracle),(counts,got,len(oracle))
            count_cases += 1
            prefixes={w[:i] for w in oracle for i in range(len(w)+1)}
            for p in prefixes:
                actual=sum(w[:len(p)] == p for w in oracle)
                expected=prefix_count(counts,p)
                assert expected==actual,(counts,p,expected,actual)
                prefix_cases+=1
            word_cases+=len(oracle)
    return count_cases,prefix_cases,word_cases

if __name__ == '__main__':
    start=perf_counter(); n=test()
    print('EXHAUSTIVE count_vectors=%d valid_prefixes=%d words=%d status=PASS elapsed=%.2fs'%(*n,perf_counter()-start))
    # Extreme legal length: 44*123+3*122 = 5778, all within 4..123.
    for counts in [(123,)*44+(122,)*3, (100,)*47, (4,)*47]:
        start=perf_counter(); x=suffix_count(counts,0)
        print('PROFILE m=%d L=%d digits=%d wall=%.3fs' %(len(counts),sum(counts),int(x.bit_length()*0.30103)+1,perf_counter()-start))
