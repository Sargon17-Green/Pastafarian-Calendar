#!/usr/bin/env python3
"""Stage 55 independent exact Python witness for MATLAB AFTER_4 -> AFTER_5.

One-step interval verification only: not the canonical five-field Oracle or Soak.
The mathematical child counter is an insertion/binomial DP developed separately
from MATLAB's endpoint and adjoint cursor algorithms. Inputs are digest-pinned.
"""
import argparse
from pathlib import Path
import sys
from zipfile import ZipFile

from stage55_after4_interval_witness import insertion_count, brute_count, read_checkpoint

sys.set_int_max_str_digits(0)
OLD = 'STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_4.json'
NEW = 'STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_5.json'
OLD_SHA = '27103195cc127f81cbed994085ac3e1d2417f91600c083006327be6e61db83e4'
NEW_SHA = '285da1744f964b96cf4c1b33a0dcf11fb23a07b0ebb2a07ab57a554410e0e5b2'


def small_brute_gate():
    cases = 0
    for lengths in ((1, 1), (2, 1), (1, 2), (2, 2), (3, 2), (2, 3), (2, 2, 2)):
        for opened in range(len(lengths) + 1):
            got = insertion_count(list(lengths), opened)
            expected = brute_count(lengths, opened)
            assert got == expected, (lengths, opened, got, expected)
            cases += 1
    assert cases == 22
    print(f'STAGE55_AFTER5_SMALL_BRUTE_PASS CASES={cases}')


def run(artifact_zip):
    small_brute_gate()
    with ZipFile(artifact_zip) as z:
        assert sorted(z.namelist()).count(OLD) == 1
        assert sorted(z.namelist()).count(NEW) == 1
        old = read_checkpoint(z, OLD, OLD_SHA)
        new = read_checkpoint(z, NEW, NEW_SHA)
    lengths = old['originalLengths']
    assert lengths == new['originalLengths'] and len(lengths) == 45
    assert sum(lengths) == 4244 and all(type(n) is int and n >= 1 for n in lengths)
    before, after = old['remaining'], new['remaining']
    assert len(before) == len(after) == 45
    assert before[:4] == [n - 1 for n in lengths[:4]]
    assert before[4:] == lengths[4:]
    assert after[:4] == before[:4] and after[4] == before[4] - 1
    assert after[5:] == before[5:]
    assert old['stepsComputed'] == 4 and new['stepsComputed'] == 5
    assert old['openedUpTo'] == 4 and new['openedUpTo'] == 5
    assert old['closedUpTo'] == new['closedUpTo'] == 0
    assert old['done'] is False and new['done'] is False
    assert sum(before) == 4240 and sum(after) == 4239
    parent_rank, parent_count = int(old['rankDecimal']), int(old['countDecimal'])
    child_rank, child_count = int(new['rankDecimal']), int(new['countDecimal'])
    assert 1 <= parent_rank <= parent_count and 1 <= child_rank <= child_count
    print('STAGE55_AFTER5_PINNED_STRUCTURAL_PASS DAYS=4244 PREFIX=1,2,3,4,5 '
          f'AFTER5_SHA256={NEW_SHA} REMAINING=4239')

    # Exactly months 1..5 are possible next: 1..4 already opened,
    # month 5 is the only permitted first-time opening; no month closes.
    blocks = []
    for symbol in range(1, 6):
        residual = before.copy()
        assert residual[symbol - 1] > 1
        residual[symbol - 1] -= 1
        opened = 5 if symbol == 5 else 4
        blocks.append(insertion_count(residual, opened))
        assert blocks[-1] > 0
        print(f'STAGE55_AFTER5_INDEPENDENT_BLOCK SYMBOL={symbol} '
              f'DIGITS={len(str(blocks[-1]))}')
    assert sum(blocks) == parent_count, 'five children must partition parent'
    assert blocks[4] == child_count, 'selected fifth child count must match Native'
    lower = sum(blocks[:4])
    assert lower == parent_rank - child_rank, 'independent offset must match rank shift'
    assert lower < parent_rank <= lower + blocks[4]
    assert parent_rank - lower == child_rank
    print('STAGE55_AFTER5_INDEPENDENT_INTERVAL_PASS CHOICES=5 PREFIX=1,2,3,4,5 '
          f'PARENT_DIGITS={len(str(parent_count))} CHILD_DIGITS={len(str(child_count))} '
          f'RANK_OFFSET_DIGITS={len(str(lower))}')
    print('STAGE55_FULL_YEAR_ORACLE_NOT_VERIFIED')
    print('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED')
    print('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('artifact_zip', type=Path)
    run(parser.parse_args().artifact_zip)
