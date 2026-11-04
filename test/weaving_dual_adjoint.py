#!/usr/bin/env python3
"""DISCOVERY03 research: exact shared reverse-adjoint transfer, not Chapel production.

The one-dimensional forward transfer is reused from same-branch research.
Its transpose is an independently implemented reverse prefix-sum. Finite
acceptance uses the independent complete enumeration / occurrence-poset oracle.
A bounded 6-symbol median-prefix probe does NOT imply full-year rank PASS.
"""
from collections import Counter
from itertools import product
from time import monotonic
from resource import getrusage, RUSAGE_SELF
from hashlib import sha256

from weaving_prefix_batch import transfer, extend_spec
from weaving_prefix_transfer import weight, count_prefix

class DualWeaving:
    def __init__(self, lengths):
        if not lengths or any(type(x) is not int or x < 1 for x in lengths):
            raise ValueError("positive integer lengths required")
        self.lengths = tuple(lengths)
        self.m = len(lengths)
        self.n = sum(lengths)
        self.used = [0] * (self.m + 1)
        self.opened = self.closed = self.position = 0
        self.specs = [None, None] + [(0, 0, -1, 0)] * (self.m - 1)
        self.sizes = [0] * (self.m + 1)
        self.states = [None] * (self.m + 1)
        n = lengths[0]
        v = [0] * (n + 1)
        v[1] = 1
        self.states[1], self.sizes[1] = v, n
        for j in range(2, self.m + 1):
            v = transfer(v, n, lengths[j-1], self.specs[j])
            n += lengths[j-1]
            self.states[j], self.sizes[j] = v, n
        self.total = sum(v)
        self.cached = None

    def eligible(self, c):
        if not 1 <= c <= self.m:
            return False
        left = self.lengths[c-1] - self.used[c]
        return (left > 0 and c <= self.opened + 1
                and (left != 1 or c == self.closed + 1))

    @staticmethod
    def transpose(after, n, k, spec):
        """For T[i+1,p]=[p<=i]*weight(i): T^t v[p]=sum(i>=p)v[i+1]*weight(i)."""
        out = [0] * (n + 1)
        acc = 0
        q = spec[0]
        for i in range(n, -1, -1):
            if after[i+1] and q <= n:
                w = weight(i, n, k, *spec)
                if w:
                    acc += after[i+1] * w
            out[i] = acc
        return out

    def blocks(self):
        if self.cached is not None:
            return self.cached
        # Stream reverse-adjoint vectors to bound memory. At month j, the
        # suffix only sees the candidate as an older letter for every c<j.
        adj = [1] * (self.n + 1)
        out = [0] * (self.m + 1)
        for j in range(self.m, 1, -1):
            if self.eligible(j):
                own = extend_spec(self.specs[j], j, j)
                v = transfer(self.states[j-1], self.sizes[j-1],
                             self.lengths[j-1], own)
                out[j] = sum(a*b for a, b in zip(adj, v))
            older = extend_spec(self.specs[j], j, 1)
            adj = self.transpose(adj, self.sizes[j-1],
                                 self.lengths[j-1], older)
        if self.eligible(1):
            out[1] = sum(a*b for a, b in zip(adj, self.states[1]))
        if sum(out) != self.total:
            raise AssertionError(("candidate partition", self.position))
        self.cached = tuple(out)
        return self.cached

    def take(self, c):
        if not self.eligible(c):
            raise ValueError("illegal next symbol")
        ways = self.blocks()[c]
        if ways <= 0:
            raise ValueError("no valid continuation")
        start = max(2, c)
        v = self.states[start-1]
        for j in range(start, self.m + 1):
            self.specs[j] = extend_spec(self.specs[j], j, c)
            v = transfer(v, self.sizes[j-1], self.lengths[j-1],
                         self.specs[j])
            self.states[j] = v
        self.used[c] += 1
        self.position += 1
        if self.used[c] == 1:
            self.opened += 1
        if self.used[c] == self.lengths[c-1]:
            self.closed += 1
        self.total = ways
        self.cached = None
        assert self.total == sum(self.states[self.m])


def dual_unrank(lengths, rank):
    s = DualWeaving(lengths)
    if type(rank) is not int or not 0 <= rank < s.total:
        raise ValueError("invalid rank")
    word = []
    for _ in range(s.n):
        for c, ways in enumerate(s.blocks()[1:], 1):
            if rank >= ways:
                rank -= ways
            else:
                s.take(c)
                word.append(c)
                break
        else:
            raise AssertionError("no continuation")
    assert rank == 0 and s.total == 1
    return tuple(word)


def dual_rank(lengths, word):
    s = DualWeaving(lengths)
    if len(word) != s.n or Counter(word) != Counter(
            {i+1: k for i, k in enumerate(lengths)}):
        raise ValueError("invalid multiplicity")
    rank = 0
    for c in word:
        rank += sum(s.blocks()[1:c])
        s.take(c)
    assert s.total == 1
    return rank


def test_finite():
    from weaving_small_exact_oracle import brute_words, poset_oracle
    cases = [p for m in range(1, 5)
             for p in product(range(1, 5), repeat=m) if sum(p) <= 8]
    cases += [(2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
              (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
              (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    roundtrips = partitions = 0
    for lengths in cases:
        accepted = brute_words(lengths)
        count, oracle_rank, oracle_unrank, _ = poset_oracle(lengths)
        assert DualWeaving(lengths).total == count == len(accepted)
        for i, word in enumerate(accepted):
            assert dual_unrank(lengths, i) == oracle_unrank(i) == word
            assert dual_rank(lengths, word) == oracle_rank(word) == i
            roundtrips += 2
            state = DualWeaving(lengths)
            for symbol in word:
                assert sum(state.blocks()) == state.total
                state.take(symbol)
                partitions += 1
    assert len(cases) == 137 and roundtrips == 1982 and partitions == 8361
    print("WEAVING_DUAL_FINITE_CASES=137")
    print("WEAVING_DUAL_FINITE_RANK_ROUNDTRIPS=1982")
    print("WEAVING_DUAL_FINITE_PARTITIONS=8361")
    print("WEAVING_DUAL_FINITE_RESULT=PASS")


def test_median_prefix():
    from weaving_reachability_oracle import MONTH_LENGTHS
    months = MONTH_LENGTHS
    assert len(months) == 45 and sum(months) == 4244
    started = monotonic()
    state = DualWeaving(months)
    root = state.total
    assert root.bit_length() == 22470
    digest = sha256(root.to_bytes((root.bit_length()+7)//8, "big")).hexdigest()
    assert digest == "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
    # This deliberately probes ONLY the first six choices for total//2.
    residual_rank = root // 2
    prefix = []
    for _ in range(6):
        blocks = state.blocks()
        for c in range(1, 46):
            if residual_rank >= blocks[c]:
                residual_rank -= blocks[c]
            else:
                state.take(c)
                prefix.append(c)
                break
        else:
            raise AssertionError("no legal median-prefix transition")
    assert tuple(prefix) == (1, 2, 3, 4, 5, 6)
    assert state.total == count_prefix(months, tuple(prefix))
    elapsed = monotonic() - started
    rss = getrusage(RUSAGE_SELF).ru_maxrss
    assert elapsed < 25.0 and rss < 512*1024, (elapsed, rss)
    print("WEAVING_DUAL_FULL_MONTHS=45")
    print("WEAVING_DUAL_FULL_DAYS=4244")
    print("WEAVING_DUAL_MEDIAN_PREFIX_SYMBOLS=6")
    print("WEAVING_DUAL_MEDIAN_PREFIX_SECONDS=" + format(elapsed, ".3f"))
    print("WEAVING_DUAL_MEDIAN_PREFIX_RSS_KIB=" + str(rss))
    print("WEAVING_DUAL_MEDIAN_PREFIX_RESULT=PASS")
    print("WEAVING_DUAL_FULL_MEDIAN_RANK_UNRANK=NOT_TESTED")


if __name__ == "__main__":
    test_finite()
    test_median_prefix()
