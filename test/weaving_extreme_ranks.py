#!/usr/bin/env python3
"""DISCOVERY03 research only: exact lexicographic extreme ranks via successors.

A finite state contains remaining multiplicities and the first-open/last-close
frontiers. Every locally legal next symbol admits a legal completion: append
all remaining copies in increasing symbol order. Consequently min/max greedy
completion and rightmost-pivot successor/predecessor are exact.

This algorithm is deliberately restricted to low ranks near zero. It is not
an arbitrary-rank replacement for the incremental transfer DP and is not
part of Chapel production.
"""
from collections import Counter
from itertools import product
from resource import RUSAGE_SELF, getrusage
from time import monotonic


class Frontier:
    def __init__(self, lengths):
        if not lengths or any(type(v) is not int or v < 1 for v in lengths):
            raise ValueError('positive integer lengths required')
        self.lengths = tuple(lengths)
        self.used = [0] * len(lengths)
        self.opened = self.closed = 0

    def legal(self, letter):
        if type(letter) is not int or not 1 <= letter <= len(self.lengths):
            return False
        u, size = self.used[letter - 1], self.lengths[letter - 1]
        return (u < size and (u != 0 or letter == self.opened + 1)
                and (u != size - 1 or letter == self.closed + 1))

    def take(self, letter):
        if not self.legal(letter):
            raise ValueError('illegal prefix')
        i = letter - 1
        if self.used[i] == 0:
            self.opened += 1
        self.used[i] += 1
        if self.used[i] == self.lengths[i]:
            self.closed += 1

    def undo(self, letter):
        i = letter - 1
        if not 0 <= i < len(self.used) or not self.used[i]:
            raise ValueError('undo without letter')
        if self.used[i] == self.lengths[i]:
            self.closed -= 1
        self.used[i] -= 1
        if self.used[i] == 0:
            self.opened -= 1

    def complete(self, largest=False):
        answer = []
        left = sum(self.lengths) - sum(self.used)
        alphabet = (range(len(self.lengths), 0, -1) if largest
                    else range(1, len(self.lengths) + 1))
        for _ in range(left):
            for letter in alphabet:
                if self.legal(letter):
                    self.take(letter)
                    answer.append(letter)
                    break
            else:
                raise AssertionError('no legal extension')
        return tuple(answer)


def extreme_word(lengths, largest=False):
    return Frontier(lengths).complete(largest)


def adjacent_word(lengths, word, forward=True):
    """Rightmost legal pivot, then lex-min/lex-max suffix."""
    state = Frontier(lengths)
    if len(word) != sum(lengths):
        raise ValueError('incorrect length')
    for c in word:
        state.take(c)
    m = len(lengths)
    for i in range(len(word) - 1, -1, -1):
        state.undo(word[i])
        choices = (range(word[i] + 1, m + 1) if forward
                   else range(word[i] - 1, 0, -1))
        for c in choices:
            if state.legal(c):
                state.take(c)
                return tuple(word[:i]) + (c,) + state.complete(not forward)
    return None


def near_zero_unrank(lengths, rank, max_steps=16):
    if type(rank) is not int or not 0 <= rank <= max_steps:
        raise ValueError('rank not within bounded extreme window')
    word = extreme_word(lengths)
    for _ in range(rank):
        word = adjacent_word(lengths, word)
        if word is None:
            raise ValueError('rank exceeds legal count')
    return word


def near_zero_rank(lengths, word, max_steps=16):
    minimal = extreme_word(lengths)
    seen = tuple(word)
    for r in range(max_steps + 1):
        if seen == minimal:
            return r
        seen = adjacent_word(lengths, seen, forward=False)
        if seen is None:
            raise ValueError('word outside bounded extreme window')
    raise ValueError('word outside bounded extreme window')


def independent_enumeration(lengths):
    """Enumerate multiplicity words and filter complete positions, no frontiers."""
    left, word, accepted = list(lengths), [], []
    n = sum(lengths)
    def dfs():
        if len(word) == n:
            first = [word.index(c) for c in range(1, len(lengths) + 1)]
            last = [n - 1 - word[::-1].index(c)
                    for c in range(1, len(lengths) + 1)]
            if first == sorted(first) and last == sorted(last):
                accepted.append(tuple(word))
            return
        for i, count in enumerate(left):
            if count:
                left[i] -= 1
                word.append(i + 1)
                dfs()
                word.pop()
                left[i] += 1
    dfs()
    return accepted


def check_word_independently(lengths, word):
    n, m = sum(lengths), len(lengths)
    assert len(word) == n
    assert Counter(word) == Counter({i + 1: k for i, k in enumerate(lengths)})
    first = [word.index(c) for c in range(1, m + 1)]
    last = [n - 1 - word[::-1].index(c) for c in range(1, m + 1)]
    assert all(a < b for a, b in zip(first, first[1:]))
    assert all(a < b for a, b in zip(last, last[1:]))


def test_finite():
    cases = [p for m in range(1, 5) for p in product(range(1, 5), repeat=m)
             if sum(p) <= 8]
    cases += [(2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
              (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
              (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    roundtrips = neighbors = 0
    for lengths in cases:
        words = independent_enumeration(lengths)
        assert extreme_word(lengths) == words[0]
        assert extreme_word(lengths, True) == words[-1]
        for i, word in enumerate(words):
            assert adjacent_word(lengths, word) == (words[i + 1] if i+1 < len(words) else None)
            assert adjacent_word(lengths, word, False) == (words[i - 1] if i else None)
            neighbors += 2
            assert near_zero_unrank(lengths, i, max_steps=len(words)) == word
            assert near_zero_rank(lengths, word, max_steps=len(words)) == i
            roundtrips += 2
    assert len(cases) == 137 and roundtrips == 1982 and neighbors == 1982
    print('WEAVING_EXTREME_FINITE_CASES=137')
    print('WEAVING_EXTREME_FINITE_NEIGHBORS=1982')
    print('WEAVING_EXTREME_FINITE_RANK_ROUNDTRIPS=1982')
    print('WEAVING_EXTREME_FINITE_RESULT=PASS')


def test_large_bounded():
    from weaving_reachability_oracle import MONTH_LENGTHS
    lengths = MONTH_LENGTHS
    assert len(lengths) == 45 and sum(lengths) == 4244
    t0 = monotonic()
    minimum = extreme_word(lengths)
    candidates = []
    for r in (1, 2):
        start = monotonic()
        word = near_zero_unrank(lengths, r, max_steps=2)
        assert word != minimum
        check_word_independently(lengths, word)
        assert near_zero_rank(lengths, word, max_steps=2) == r
        assert word == near_zero_unrank(lengths, r, max_steps=2)
        elapsed = monotonic() - start
        rss = getrusage(RUSAGE_SELF).ru_maxrss
        assert elapsed < 180 and rss < 512 * 1024, (r, elapsed, rss)
        candidates.append(word)
        print(f'WEAVING_EXTREME_FULL_RANK_{r}_SECONDS={elapsed:.3f}')
        print(f'WEAVING_EXTREME_FULL_RANK_{r}_RSS_KIB={rss}')
    assert minimum < candidates[0] < candidates[1]
    assert adjacent_word(lengths, minimum) == candidates[0]
    assert adjacent_word(lengths, candidates[0]) == candidates[1]
    assert adjacent_word(lengths, candidates[1], forward=False) == candidates[0]
    assert adjacent_word(lengths, candidates[0], forward=False) == minimum
    print('WEAVING_EXTREME_FULL_MONTHS=45')
    print('WEAVING_EXTREME_FULL_DAYS=4244')
    print('WEAVING_EXTREME_FULL_NONTRIVIAL_RANKS=2')
    print(f'WEAVING_EXTREME_FULL_TOTAL_SECONDS={monotonic()-t0:.3f}')
    print('WEAVING_EXTREME_FULL_RESULT=PASS')
    print('WEAVING_EXTREME_ARBITRARY_RANKS=NOT_TESTED')


if __name__ == '__main__':
    test_finite()
    test_large_bounded()
