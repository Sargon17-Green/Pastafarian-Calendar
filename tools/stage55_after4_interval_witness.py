#!/usr/bin/env python3
"""Stage 55: separate Python exact-integer interval witness for native AFTER_3/4.

Not a full-year normative oracle or cross-engine soak. Source of truth is the
pinned pair of native checkpoint JSONs, checked against known SHA-256 digests.
This witness independently counts eligible lexical child blocks using a
binomial insertion construction, rather than MATLAB's adjoint rank selector.
"""
import argparse
from hashlib import sha256
from itertools import permutations
from math import comb
import json
from pathlib import Path
import sys
from zipfile import ZipFile

sys.set_int_max_str_digits(0)
PREV_FILE = 'STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_3.json'
NEXT_FILE = 'STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_4.json'
PREV_SHA = 'ace93f07ba132027edb6c2eb750b1c6e509efb2ead7839b560c94139f4f96504'
NEXT_SHA = '27103195cc127f81cbed994085ac3e1d2417f91600c083006327be6e61db83e4'


def insertion_count(lengths, already_open):
    """Exact count of legal suffixes, independent binomial insertion DP.

    Add month IDs in increasing order. Last occurrence of newly added month
    is fixed at the end by closing order; insert its earlier occurrences
    around the old word. Until all pre-opened months have been consumed,
    first-occurrence ordering is already satisfied in the historical prefix.
    Thereafter, newly added month's first must follow the old maximum first.
    State maps position of the largest active month's first occurrence to
    number of words. Binomial coefficients are computed by math.comb.
    """
    assert lengths and all(type(x) is int and x >= 1 for x in lengths)
    assert 0 <= already_open <= len(lengths)
    first_at = [0, 1]  # one all-1 word, month-1 first is at position 1
    prefix_length = lengths[0]
    for i, multiple in enumerate(lengths[1:], 2):
        total = sum(first_at)
        new = [0] * (prefix_length + 2)
        preceding = 0
        # Before month i first occurs at position p, exactly p-1 old
        # symbols appear; all but one remaining i symbols may be placed
        # freely among slots before the obligatorily final i.
        for p in range(1, prefix_length + 2):
            if p - 1 < len(first_at):
                preceding += first_at[p - 1]
            eligible = total if i <= already_open + 1 else preceding
            if multiple == 1:
                if p == prefix_length + 1:
                    new[p] = eligible
            else:
                new[p] = eligible * comb(prefix_length + multiple - 1 - p,
                                          multiple - 2)
        first_at = new
        prefix_length += multiple
    return sum(first_at)


def brute_count(lengths, already_open):
    pool = tuple(i for i, n in enumerate(lengths, 1) for _ in range(n))
    count = 0
    for word in set(permutations(pool)):
        first = [word.index(i) for i in range(1, len(lengths)+1)]
        last = [len(word) - 1 - word[::-1].index(i)
                for i in range(1, len(lengths)+1)]
        if last == sorted(last) and first[already_open:] == sorted(first[already_open:]):
            # For already opened months, first occurrences are in the past;
            # only first-new vs first-new order is constrained.
            count += 1
    return count


def read_checkpoint(z, name, expected_sha):
    b = z.read(name)
    actual = sha256(b).hexdigest()
    assert actual == expected_sha, (name, actual)
    obj = json.loads(b)
    assert set(obj) == {'schema','originalLengths','remaining','openedUpTo',
                        'closedUpTo','rankDecimal','countDecimal','done',
                        'stepsComputed'}
    assert obj['schema'] == 'pastafari-weave-cursor-v1'
    for k in ('rankDecimal', 'countDecimal'):
        val = obj[k]
        assert isinstance(val, str) and val.isascii() and val[0] in '123456789' and val.isdigit()
    return obj


def run(zip_file):
    # Brute crosschecks are restricted to tiny fully unopened examples;
    # this is not a full reference enumerator for the year-5000 data.
    small = [(1,1), (2,1), (1,2), (2,2), (3,2), (2,3), (2,2,2)]
    cases = 0
    for lengths in small:
        for preopened in range(len(lengths) + 1):
            expected = brute_count(lengths, preopened)
            got = insertion_count(list(lengths), preopened)
            assert got == expected, (lengths, preopened, got, expected)
            cases += 1
    print('STAGE55_AFTER4_SMALL_BRUTE_PASS CASES='+str(cases))
    with ZipFile(zip_file) as z:
        old = read_checkpoint(z, PREV_FILE, PREV_SHA)
        new = read_checkpoint(z, NEXT_FILE, NEXT_SHA)
    L = old['originalLengths']
    assert L == new['originalLengths'] and len(L)==45 and sum(L)==4244
    r3, r4 = old['remaining'], new['remaining']
    assert r3[:3] == [L[0]-1,L[1]-1,L[2]-1]
    assert r3[3:] == L[3:] and r4[:3]==r3[:3]
    assert r4[3]==r3[3]-1 and r4[4:]==r3[4:]
    assert old['openedUpTo']==3 and new['openedUpTo']==4
    assert old['closedUpTo']==new['closedUpTo']==0
    assert old['stepsComputed']==3 and new['stepsComputed']==4
    assert old['done'] is False and new['done'] is False
    assert sum(r3)==4241 and sum(r4)==4240
    rank3,count3 = int(old['rankDecimal']),int(old['countDecimal'])
    rank4,count4 = int(new['rankDecimal']),int(new['countDecimal'])
    assert 1<=rank3<=count3 and 1<=rank4<=count4
    print('STAGE55_AFTER4_PINNED_STRUCTURAL_PASS DAYS=4244 PREFIX=1,2,3,4 SHA256_AFTER4='+NEXT_SHA)

    # At the fourth step, only 1,2,3,4 are permitted. The three preceding
    # lexical blocks and chosen fourth block must partition the old suffix.
    blocks = []
    for symbol in (1,2,3,4):
        child=r3.copy()
        assert child[symbol-1]>1
        child[symbol-1]-=1
        opened = 4 if symbol==4 else 3
        blocks.append(insertion_count(child, opened))
        print('STAGE55_AFTER4_INDEPENDENT_BLOCK', symbol,
              'DIGITS='+str(len(str(blocks[-1]))))
    assert blocks[3] == count4, 'selected child count differs from native checkpoint'
    assert sum(blocks) == count3, 'sum(child blocks) differs from native parent'
    preceding = sum(blocks[:3])
    assert preceding == rank3-rank4, 'rank subtraction differs from child interval'
    assert preceding < rank3 <= preceding + blocks[3]
    print('STAGE55_AFTER4_INDEPENDENT_INTERVAL_PASS CHOICES=4 PREFIX=1,2,3,4',
          'PARENT_DIGITS='+str(len(str(count3))),
          'CHILD_DIGITS='+str(len(str(count4))),
          'RANK_OFFSET_DIGITS='+str(len(str(preceding))))
    print('STAGE55_FULL_YEAR_ORACLE_NOT_VERIFIED')
    print('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED')
    print('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED')


if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('artifact_zip', type=Path)
    args=ap.parse_args()
    run(args.artifact_zip)
