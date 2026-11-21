#!/usr/bin/env python3
"""Independent bounded endpoint-path coefficient / prefix-unrank QA.
PROJECT_ID: PC-BRANCH-LUA-HAITIAN. QA ONLY. Does not invoke Lua or full date.
All counts are exact integers; resource limits are NOT normative validity limits.
"""
from collections import defaultdict
from functools import lru_cache
from itertools import product
from math import factorial

MAX_MONTHS = 4
MAX_DAYS = 12
MAX_MONOMIALS = 150000

class ResourceBound(Exception):
    pass

def guard(lengths):
    if not lengths or any(type(x) is not int or x < 2 for x in lengths):
        raise ValueError('QA_INPUT')
    if len(lengths) > MAX_MONTHS or sum(lengths) > MAX_DAYS:
        raise ResourceBound('NOT_EVALUATED_QA_DOMAIN')

@lru_cache(None)
def gap_paths(m, opened, closed):
    """Dyck completions, each with a gap at the current and every next endpoint state."""
    if opened == m and closed == m:
        return (((),),)
    active = tuple(range(closed, opened))
    out = []
    if opened < m:
        for tail in gap_paths(m, opened + 1, closed):
            out.append((active,) + tail)
    if closed < opened:
        for tail in gap_paths(m, opened, closed + 1):
            out.append((active,) + tail)
    return tuple(out)

@lru_cache(None)
def gap_deltas(active, caps):
    """Enumerate sparse terms of 1/(1 - sum(active variables)), truncated."""
    m = len(caps)
    out = []
    for exps in product(*(range(caps[i] + 1) for i in active)):
        delta = [0] * m
        for i, e in zip(active, exps):
            delta[i] = e
        weight = factorial(sum(exps))
        for e in exps:
            weight //= factorial(e)
        out.append((tuple(delta), weight))
    return tuple(out)

def coefficient(caps, gaps):
    """Exact coefficient of the product of rational gap factors, no word enumeration."""
    m = len(caps)
    poly = {(0,) * m: 1}
    for active in gaps:
        if not active:
            continue
        choices = gap_deltas(active, caps)
        updated = defaultdict(int)
        for used, ways in poly.items():
            for delta, weight in choices:
                nxt = tuple(used[i] + delta[i] for i in range(m))
                if all(nxt[i] <= caps[i] for i in range(m)):
                    updated[nxt] += ways * weight
        if len(updated) > MAX_MONOMIALS:
            raise ResourceBound('POLYNOMIAL_STATE_BUDGET')
        poly = updated
    return poly.get(caps, 0)

@lru_cache(None)
def suffix_count(lengths, prefix):
    """Prefix-constrained endpoint-path generating-function count."""
    guard(lengths)
    m = len(lengths)
    remaining = list(lengths)
    opened = closed = 0
    for label in prefix:
        if type(label) is not int or not 0 <= label < m or remaining[label] == 0:
            return 0
        if remaining[label] == lengths[label]:
            if label != opened:
                return 0
            opened += 1
        elif remaining[label] == 1:
            if label != closed:
                return 0
            closed += 1
        else:
            if not (closed <= label < opened):
                return 0
        remaining[label] -= 1
    if all(v == 0 for v in remaining):
        return 1
    caps = tuple(remaining[i] - int(i >= opened) - int(i >= closed) for i in range(m))
    if min(caps) < 0:
        return 0
    return sum(coefficient(caps, gaps) for gaps in gap_paths(m, opened, closed))

def unrank(lengths, rank1):
    guard(lengths)
    total = suffix_count(lengths, ())
    if type(rank1) is not int or not 1 <= rank1 <= total:
        raise ValueError('QA_RANK')
    prefix = ()
    while len(prefix) < sum(lengths):
        for label in range(len(lengths)):
            block = suffix_count(lengths, prefix + (label,))
            if rank1 > block:
                rank1 -= block
            elif block:
                prefix += (label,)
                break
        else:
            raise AssertionError('UNRANK_EXHAUSTED')
    assert rank1 == 1
    return prefix

def independent_words(lengths):
    """Brute-force multiset-word oracle, independent from endpoints/GFs."""
    out = []
    left = list(lengths)
    word = []
    def walk():
        if not any(left):
            first = [word.index(i) for i in range(len(lengths))]
            last = [len(word) - 1 - word[::-1].index(i) for i in range(len(lengths))]
            if first == sorted(first) and last == sorted(last):
                out.append(tuple(word))
            return
        for i in range(len(left)):
            if left[i]:
                left[i] -= 1
                word.append(i)
                walk()
                word.pop()
                left[i] += 1
    walk()
    return out

def selftest():
    fixtures = [v for m in range(1, 4) for v in product((2, 3, 4), repeat=m)
                if sum(v) <= MAX_DAYS]
    fixtures += [(2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 2, 2), (3, 3, 2, 2)]
    cases = prefixes = ranks = 0
    for lengths in fixtures:
        brute = independent_words(lengths)
        assert suffix_count(lengths, ()) == len(brute), (lengths, 'count')
        cases += 1
        probes = {(), (0,), (len(lengths)-1,), (0,)*2}
        if brute:
            for idx in (0, len(brute)//2, len(brute)-1):
                probes.add(brute[idx][:min(4, sum(lengths))])
        for prefix in probes:
            expected = sum(word[:len(prefix)] == prefix for word in brute)
            actual = suffix_count(lengths, prefix)
            assert actual == expected, (lengths, prefix, actual, expected)
            prefixes += 1
        if brute:
            for idx in sorted({0, len(brute)//2, len(brute)-1}):
                actual = unrank(lengths, idx+1)
                assert actual == brute[idx], (lengths, idx, actual, brute[idx])
                ranks += 1
            for bad in (0, len(brute)+1):
                try:
                    unrank(lengths, bad)
                    raise AssertionError('rejected rank accepted')
                except ValueError:
                    pass
    assert suffix_count((2,2), (1,)) == 0
    assert suffix_count((2,2), (0,0,1,1)) == 1
    try:
        suffix_count((123,)*43+(5,), ())
        raise AssertionError('large case incorrectly evaluated')
    except ResourceBound as e:
        assert str(e) == 'NOT_EVALUATED_QA_DOMAIN'
    print('SPARSE_PATH_QA_CASES:', cases)
    print('SPARSE_PATH_PREFIX_ORACLE:', prefixes)
    print('SPARSE_PATH_LEX_UNRANK:', ranks)
    print('REAL_47_MONTHS=NOT_EVALUATED_QA_DOMAIN; FULL_DATE=NOT_RUN; PRODUCTION=UNCHANGED')

if __name__ == '__main__':
    selftest()
