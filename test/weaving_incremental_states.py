#!/usr/bin/env python3
"""Research-only exact lexicographic rank/unrank with persistent transfer states.

All calculation uses earlier independent transfer theorem; no Chapel production imports.
This reduces repeated baseline recomputation, NOT the candidate-probe asymptotic
bound. A full year runtime bound is deliberately not claimed here.
"""
from collections import Counter
from itertools import product
from time import monotonic

from weaving_prefix_batch import transfer, extend_spec
from weaving_prefix_transfer import count_prefix


class IncrementalWeaving:
    def __init__(self, lengths):
        if not lengths or any(type(x) is not int or x <= 0 for x in lengths):
            raise ValueError('lengths must be nonempty positive integers')
        self.lengths = tuple(lengths)
        self.m = len(lengths)
        self.n = sum(lengths)
        self.used = [0] * (self.m + 1)
        self.opened = self.closed = self.position = 0
        self.specs = [None, None] + [(0, 0, -1, 0)] * (self.m - 1)
        self.sizes = [0] * (self.m + 1)
        self.states = [None] * (self.m + 1)
        size = lengths[0]
        base = [0] * (size + 1)
        base[1] = 1
        self.states[1] = base
        self.sizes[1] = size
        for j in range(2, self.m + 1):
            base = transfer(base, size, lengths[j-1], self.specs[j])
            size += lengths[j-1]
            self.states[j] = base
            self.sizes[j] = size
        self.total = sum(self.states[self.m])

    def probe(self, candidate):
        """Return exact continuation count with only one temporary DP vector."""
        if not isinstance(candidate, int) or not 1 <= candidate <= self.m:
            raise ValueError('candidate outside month alphabet')
        left = self.lengths[candidate-1] - self.used[candidate]
        if (not left or candidate > self.opened + 1 or
                (left == 1 and candidate != self.closed + 1)):
            return 0
        # Prefix containing no letters beyond month 1 has the same DP base.
        start = max(2, candidate)
        base = self.states[start - 1]
        for j in range(start, self.m + 1):
            spec = extend_spec(self.specs[j], j, candidate)
            base = transfer(base, self.sizes[j-1], self.lengths[j-1], spec)
        return sum(base)

    def take(self, candidate, count):
        """Rebuild only changed suffix in-place; memory O(m*N) bigint slots."""
        if not 0 < count <= self.total:
            raise ValueError('zero/invalid candidate count')
        start = max(2, candidate)
        base = self.states[start-1]
        for j in range(start, self.m + 1):
            self.specs[j] = extend_spec(self.specs[j], j, candidate)
            base = transfer(base, self.sizes[j-1], self.lengths[j-1], self.specs[j])
            self.states[j] = base
        self.used[candidate] += 1
        self.position += 1
        if self.used[candidate] == 1:
            assert candidate == self.opened + 1
            self.opened += 1
        if self.used[candidate] == self.lengths[candidate-1]:
            assert candidate == self.closed + 1
            self.closed += 1
        self.total = count
        assert self.total == sum(self.states[self.m])


def incremental_rank(lengths, word):
    s = IncrementalWeaving(lengths)
    if len(word) != s.n or Counter(word) != Counter(dict(enumerate(lengths, 1))):
        raise ValueError('wrong word length or multiplicity')
    rank = 0
    for symbol in word:
        for c in range(1, symbol + 1):
            count = s.probe(c)
            if c < symbol:
                rank += count
            else:
                s.take(c, count)
    assert s.total == 1 and s.position == s.n
    return rank


def incremental_unrank(lengths, rank):
    s = IncrementalWeaving(lengths)
    if not isinstance(rank, int) or not 0 <= rank < s.total:
        raise ValueError('rank outside valid range')
    word = []
    for _ in range(s.n):
        for c in range(1, s.m + 1):
            count = s.probe(c)
            if rank >= count:
                rank -= count
            else:
                s.take(c, count)
                word.append(c)
                break
        else:
            raise AssertionError('no legal next symbol')
    assert rank == 0 and s.total == 1
    return tuple(word)


def test_finite():
    # The independent brute force oracle generates complete permutations and
    # filters first/last occurrence ordering; it uses no transfer recurrence.
    from weaving_small_exact_oracle import brute_words, poset_oracle
    cases = [p for m in range(1, 5) for p in product(range(1, 5), repeat=m)
             if sum(p) <= 8]
    cases += [(2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
              (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
              (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    checks = roundtrips = 0
    for lengths in cases:
        accepted = brute_words(lengths)
        total, rank0, unrank0, _ = poset_oracle(lengths)
        s = IncrementalWeaving(lengths)
        assert s.total == total == len(accepted)
        prefixes = {word[:i] for word in accepted for i in range(len(word) + 1)}
        for prefix in prefixes:
            t = IncrementalWeaving(lengths)
            for c in prefix:
                count = t.probe(c)
                t.take(c, count)
            for c in range(1, t.m + 1):
                count = t.probe(c)
                expected = sum(word[:len(prefix)+1] == prefix + (c,)
                               for word in accepted)
                assert count == expected, (lengths, prefix, c)
                checks += 1
        for i, word in enumerate(accepted):
            assert incremental_rank(lengths, word) == rank0(word) == i
            assert incremental_unrank(lengths, i) == unrank0(i) == word
            roundtrips += 2
    assert len(cases) == 137 and checks == 17217 and roundtrips == 1982, (len(cases), checks, roundtrips)
    print('WEAVING_INCREMENTAL_CASES=137')
    print('WEAVING_INCREMENTAL_CANDIDATE_CHECKS=' + str(checks))
    print('WEAVING_INCREMENTAL_RANK_CHECKS=' + str(roundtrips))
    print('WEAVING_INCREMENTAL_FINITE_RESULT=PASS')


def test_large_bounded_probe():
    """Only bounded root/first-symbol profiling, not whole-year rank/unrank."""
    from weaving_reachability_oracle import MONTH_LENGTHS
    from resource import getrusage, RUSAGE_SELF
    from hashlib import sha256
    months = MONTH_LENGTHS
    assert len(months) == 45 and sum(months) == 4244
    t0 = monotonic()
    s = IncrementalWeaving(months)
    assert s.total == count_prefix(months)
    assert s.total.bit_length() == 22470
    digest = sha256(s.total.to_bytes((s.total.bit_length()+7)//8, 'big')).hexdigest()
    assert digest == '925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da'
    count = s.probe(1)
    assert count == s.total
    s.take(1, count)
    next1 = s.probe(1)
    next2 = s.probe(2)
    assert next1 + next2 == s.total
    assert next1 == count_prefix(months, (1, 1))
    assert next2 == count_prefix(months, (1, 2))
    assert all(s.probe(c) == 0 for c in range(3, len(months)+1))
    elapsed = monotonic() - t0
    rss = getrusage(RUSAGE_SELF).ru_maxrss
    assert elapsed < 25 and rss < 512*1024, (elapsed, rss)
    print('WEAVING_INCREMENTAL_FULL_MONTHS=45')
    print('WEAVING_INCREMENTAL_FULL_DAYS=4244')
    print('WEAVING_INCREMENTAL_FULL_PROFILE_COUNT=1')
    print('WEAVING_INCREMENTAL_FULL_SECONDS=' + format(elapsed, '.3f'))
    print('WEAVING_INCREMENTAL_FULL_RSS_KIB=' + str(rss))
    print('WEAVING_INCREMENTAL_FULL_RESULT=PASS')
    print('WEAVING_INCREMENTAL_FULL_RANK_UNRANK=NOT_TESTED')


if __name__ == '__main__':
    test_finite()
    test_large_bounded_probe()
