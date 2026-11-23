#!/usr/bin/env python3
"""Focused independent rank/offset boundary and mutation checks for WAT+Español.

Run: python3 tests/stage02_calendar_weave_boundary_qa.py
      python3 tests/stage02_calendar_weave_boundary_qa.py --enumerator-only
Independent DFS supplies expected words, not the existing WAT or weave oracle.
Large-family tests are structural only, not independent differential or Native.
"""
import argparse
import hashlib
import json
from pathlib import Path

PROJECT = 'PC-BRANCH-WAT-SPANISH'
SMALL = ((2,2,2,2), (2,3,2,2), (3,2,3), (3,3,3), (4,3,2))
LARGE = ((5,7,9,11,13,15,17,19), (3,4,5,6,7,8,9))


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def enumerate_words(lengths):
    """Enumerate allowed words in lexical order; first and last appearances
    of months must be in ascending ID order. No combinatorial-rank formula.
    """
    remaining = list(lengths)
    word, output = [], []
    def recurse(next_new):
        if not any(remaining):
            require(next_new == len(lengths), 'unfinished first appearances')
            output.append(tuple(word))
            return
        for i in range(min(next_new + 1, len(lengths))):
            if i < next_new and remaining[i] == 0:
                continue
            if i == next_new and remaining[i] != lengths[i]:
                continue
            if remaining[i] == 1 and any(remaining[:i]):
                continue
            remaining[i] -= 1
            word.append(i + 1)
            recurse(next_new + (i == next_new))
            word.pop()
            remaining[i] += 1
    recurse(0)
    require(output == sorted(set(output)), 'enumeration duplicate/order')
    return output


def rejects(fn, label):
    try:
        fn()
    except (AssertionError, ValueError):
        return
    raise AssertionError('mutation unexpectedly survived: ' + label)


def compare_pair(observed, expected):
    require(observed == expected, f'wrong month/day: {observed} != {expected}')


def offsets(word):
    selection = {0, len(word)//2, len(word)-1}
    for month in set(word):
        first = word.index(month)
        last = len(word)-1-word[::-1].index(month)
        selection.update(p for x in (first,last) for p in (x-1,x,x+1)
                         if 0 <= p < len(word))
    return sorted(selection)


def run_small(unrank, completion_table):
    word_count = offset_count = mutation_count = 0
    results = []
    for lengths in SMALL:
        valid = enumerate_words(lengths)
        size = len(valid)
        require(size == completion_table(list(lengths))[0][0], 'family cardinality')
        for rank, expected in enumerate(valid, 1):
            full = unrank(list(lengths),rank,len(expected)-1,full=True)
            require(tuple(full['word']) == expected, f'{lengths}: word rank={rank}')
            require(int(full['family_size']) == size, 'family count mismatch')
            word_count += 1
            for i in offsets(expected):
                actual = unrank(list(lengths),rank,i)
                compare_pair((actual['month_id'],actual['day_in_month']),
                             (expected[i],expected[:i+1].count(expected[i])))
                offset_count += 1
            if rank in {1, max(1,size//2), size}:
                for bad in (0,-1,size+1):
                    rejects(lambda b=bad: unrank(list(lengths),b,0),'rank')
                    mutation_count += 1
                for bad in (-1,len(expected)):
                    rejects(lambda b=bad: unrank(list(lengths),rank,b),'offset')
                    mutation_count += 1
                first = (expected[0],1)
                for wrong in (((first[0] % len(lengths))+1,1), (first[0],0),
                              (first[0],lengths[first[0]-1]+1)):
                    rejects(lambda w=wrong: compare_pair(w,first),'output')
                    mutation_count += 1
        results.append({'lengths':list(lengths),'independent_words':size})
    return {'cases':results,'words':word_count,'boundary_probes':offset_count,
            'rejected_mutations':mutation_count}


def run_large(unrank, completion_table):
    checked = 0
    results = []
    for lengths in LARGE:
        total = completion_table(list(lengths))[0][0]
        ranks = sorted({1,2,3,total//2,total-2,total-1,total})
        for rank in ranks:
            word = tuple(unrank(list(lengths),rank,sum(lengths)-1,full=True)['word'])
            require(len(word) == sum(lengths), 'large word length')
            for ident, n in enumerate(lengths,1):
                require(word.count(ident) == n, 'large multiplicity')
            require([word.index(i) for i in range(1,len(lengths)+1)] ==
                    sorted(word.index(i) for i in range(1,len(lengths)+1)),
                    'large first appearance')
            require([len(word)-1-word[::-1].index(i) for i in range(1,len(lengths)+1)] ==
                    sorted(len(word)-1-word[::-1].index(i) for i in range(1,len(lengths)+1)),
                    'large last appearance')
            for i in (0,1,len(word)//2,len(word)-2,len(word)-1):
                got = unrank(list(lengths),rank,i)
                compare_pair((got['month_id'],got['day_in_month']),
                             (word[i],word[:i+1].count(word[i])))
                checked += 1
        results.append({'lengths':list(lengths),
                        'family_rank_decimal_digits':len(str(total)),
                        'ranks_sampled':len(ranks)})
    return {'cases':results,'structural_probes':checked,
            'independent_expected_large_outputs':False}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--enumerator-only',action='store_true')
    args = p.parse_args()
    if args.enumerator_only:
        print(json.dumps({'project':PROJECT,'enumerator_only':True,
                          'families':[{'lengths':list(x),'count':len(enumerate_words(x))}
                                      for x in SMALL]},sort_keys=True))
        return
    from stage02_calendar_weave_independent_oracle import unrank_weave_at, completion_table
    small = run_small(unrank_weave_at,completion_table)
    large = run_large(unrank_weave_at,completion_table)
    source = Path(__file__).with_name('stage02_calendar_weave_independent_oracle.py')
    print(json.dumps({'project':PROJECT,'gate':'FOCUSED_QA_PASS',
                      'oracle_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                      'small_independent':small,'large_structural':large,
                      'native_pass':False,'stage02_accepted':False},sort_keys=True))


if __name__ == '__main__':
    try:
        main()
    except (AssertionError,ValueError) as exc:
        print('FOCUSED_QA_FAIL:',exc)
        raise SystemExit(1)
