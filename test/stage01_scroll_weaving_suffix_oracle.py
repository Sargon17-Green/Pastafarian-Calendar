#!/usr/bin/env python3
"""Independent Seal 32 conditional suffix QA; NOT unrestricted seal32 unrank.
Once every month is opened, the only remaining constraint is ordered last
occurrences. Reversing a uniform multiset word makes first appearances a
size-biased permutation: P(m,...,1)=product(r_i / sum(r_1..r_i)).
Thus C(r)=N! / [product((r_i-1)!) * product(prefix sums)], ignoring zeros.
A fixed opening prefix is a proper subset of the full weaving family.
"""
import argparse
import hashlib
import itertools
import json
import math
import sys
from fractions import Fraction
from pathlib import Path


def count(r):
    n = sum(r)
    den = 1
    p = 0
    for k in r:
        if k:
            p += k
            den *= math.factorial(k-1) * p
    q, rem = divmod(math.factorial(n), den)
    if rem:
        raise ArithmeticError('nonintegral count')
    return q


def branches(r, total):
    """Exact child counts from count formula ratios, not candidate code."""
    n = sum(r)
    if not n:
        return []
    p = n
    factor = Fraction(1)
    out = []
    for i in range(len(r)-1, -1, -1):
        k = r[i]
        if not k:
            continue
        if p == 1:  # only first remaining color may close
            ratio = factor / n
        else:
            factor *= Fraction(p, p-1)
            ratio = factor * Fraction(k-1, n)
        q, rem = divmod(total * ratio.numerator, ratio.denominator)
        if rem:
            raise ArithmeticError('nonintegral child count')
        if q:
            out.append((i, q))
        p -= k
    if sum(q for _, q in out) != total:
        raise AssertionError('child conservation')
    return out[::-1]


def unrank(r, rank):
    r = list(r)
    total = count(r)
    if not 0 <= rank < total:
        raise ValueError('conditional rank out of range')
    word = []
    while sum(r):
        for i, q in branches(r, total):
            if rank < q:
                r[i] -= 1
                total = q
                word.append(i+1)
                break
            rank -= q
        else:
            raise AssertionError('missing child')
    if rank != 0 or total != 1:
        raise AssertionError('terminal rank')
    return tuple(word)


def brute(r):
    counts = list(r)
    stack = []
    out = []
    def rec():
        if len(stack) == sum(r):
            last = [len(stack)-1-stack[::-1].index(i+1) for i,k in enumerate(r) if k]
            if last == sorted(last):
                out.append(tuple(stack))
            return
        for i,k in enumerate(counts):
            if k:
                counts[i] -= 1
                stack.append(i+1)
                rec()
                stack.pop()
                counts[i] += 1
    rec()
    return out


def selftest():
    shapes = ranks = 0
    for m in range(1,5):
        for r in itertools.product(range(4), repeat=m):
            if sum(r) > 8:
                continue
            words = brute(r)
            assert count(r) == len(words), r
            shapes += 1
            if sum(r):
                for i,q in branches(r, len(words)):
                    nxt = list(r)
                    nxt[i] -= 1
                    assert q == count(nxt), (r,i)
            for rank, word in enumerate(words):
                assert unrank(r,rank) == word, (r,rank)
                ranks += 1
    return shapes,ranks


def foundation(lengths):
    if len(lengths) != 44 or sum(lengths) != 4399 or min(lengths) < 4 or max(lengths) > 123:
        raise ValueError('wrong Foundation shape')
    r = [k-1 for k in lengths]
    total = count(r)
    rank = total//2
    word = tuple(range(1,45)) + unrank(r,rank)
    assert len(word) == 4399
    assert [word.count(i) for i in range(1,45)] == list(lengths)
    assert [word.index(i) for i in range(1,45)] == list(range(44))
    last = [len(word)-1-word[::-1].index(i) for i in range(1,45)]
    assert last == sorted(last)
    return dict(project_id='PC-BRANCH-FORTRAN-ENGLISH',scope='FIXED_OPENING_PREFIX_ONLY',
                month_lengths=list(lengths),fixed_prefix=list(range(1,45)),
                conditional_count=str(total),conditional_rank=str(rank),word=list(word),
                unrestricted_count_verified=False,canonical_weaving_verified=False,
                full_stage1_accepted=False)


def main():
    if hasattr(sys,'set_int_max_str_digits'):
        sys.set_int_max_str_digits(0)
    p = argparse.ArgumentParser()
    p.add_argument('--self-test',action='store_true')
    p.add_argument('--foundation-json',type=Path)
    p.add_argument('--output',type=Path)
    a = p.parse_args()
    if a.self_test:
        shapes,ranks = selftest()
        print(f'SEAL32_SUFFIX_SELFTEST={shapes} SHAPES; {ranks} RANKS')
    if a.foundation_json:
        if not a.output:
            p.error('--output required')
        data = json.loads(a.foundation_json.read_text(encoding='utf-8'))
        if data['project_id'] != 'PC-BRANCH-FORTRAN-ENGLISH' or data['foundation_year'] != 5000:
            raise ValueError('wrong project or year')
        report = foundation(data['month_lengths'])
        a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print('SEAL32_FIXED_PREFIX_44_MONTHS_4399_DAYS=PASS_CONDITIONAL_ONLY')
    if not a.self_test and not a.foundation_json:
        p.error('choose a test')

if __name__ == '__main__':
    main()
