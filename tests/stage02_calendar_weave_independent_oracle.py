#!/usr/bin/env python3
"""Source-independent combinatorial oracle for the WAT+Español Stage02 month weave.

The algorithm ranks words directly by counts of admissible continuations:
month identifiers first appear and last appear in increasing order, while each
month occurs its independently derived length. It never reads WAT memory or
uses the observed month/day to reconstruct the answer.

Run: python3 tests/stage02_calendar_weave_independent_oracle.py --selftest
Run: python3 tests/stage02_calendar_weave_independent_oracle.py /path/to/exact-trace.zip
Requires the neighboring stage02_calendar_trace_compositional_oracle.py only for
three-field trace/gate reconstruction and source/identity assertions.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import math
import sys
import zipfile
from pathlib import Path

if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(0)

PROJECT = 'PC-BRANCH-WAT-SPANISH'
LOCKED_BLOB = '70267bb5730678f81d6138a2224d6b8d9a193eb8'
TRACE_RUN = 45087126165
TRACE_SHA = 'd05ce85128ab0eabcf4f1b1712f3c97da35886a7'
ZIP_SHA256 = '2a3d163485b610a49290a087624b27514ef83c3543005e361ee39b2fc3b170ba'


def require(pred: bool, reason: str) -> None:
    if not pred:
        raise AssertionError(reason)


def completion_table(lengths: list[int]) -> list[list[int]]:
    """H[a][R] counts admissible suffixes with a months introduced,
    R outstanding occurrences of introduced months, after factoring out
    permutations of the active occurrences with ordered final appearances.

    Derivation by insertion: for new month of size q, allocate t of the R
    old active positions after its first appearance; nonfinal placements of
    the new month can be inserted in C(q-2+t,t) patterns, and the final one
    must follow the last active completion. Hence
    H[a][R] = sum_{t=0}^R C(q-2+t,t) H[a+1][q-1+t].
    """
    require(bool(lengths) and all(x >= 2 for x in lengths), 'month sizes >=2')
    m = len(lengths)
    sizes = [0]
    for size in lengths:
        sizes.append(sizes[-1] + size - 1)
    rows: list[list[int]] = [[] for _ in range(m + 1)]
    rows[m] = [1] * (sizes[m] + 1)
    for a in range(m - 1, -1, -1):
        q = lengths[a]
        acc, coefficient = 0, 1
        row: list[int] = []
        for r in range(sizes[a] + 1):
            acc += coefficient * rows[a + 1][q - 1 + r]
            row.append(acc)
            coefficient = coefficient * (q - 1 + r) // (r + 1)
        rows[a] = row
    return rows


def completion_factor(remaining: list[int], first: int, introduced: int) -> int:
    """Count permutations of the active multiset having ordered last occurrences.
    Among S_i active occurrences through month i, the final one must be i;
    choose its preceding r_i-1 placements among S_i-1. Product theorem.
    """
    result = 1
    prefix = 0
    for i in range(first, introduced):
        count = remaining[i]
        require(count > 0, 'active months must have positive remaining counts')
        prefix += count
        result *= math.comb(prefix - 1, count - 1)
    return result



def suffix_unrank_by_month_subsets(remaining: list[int], first: int,
                                   one_based_rank: int) -> list[int]:
    """Invert the final all-introduced suffix with a descending-month
    subset factorization, using standard combinadic bit-word enumeration.

    This rank convention is distinct from the chronological lexicographic
    prefix order. It partitions the residual rank by lower-month family sizes;
    the last occurrence of each higher month is forced to be the last free
    slot, while its earlier occurrences select a 0-before-1 bit pattern.
    """
    m = len(remaining)
    count = sum(remaining[first:])
    slots = list(range(count))
    output = [0] * count
    require(1 <= one_based_rank <= completion_factor(remaining, first, m),
            'suffix rank outside family')
    rank = one_based_rank
    for k in range(m - 1, first, -1):
        n = remaining[k]
        require(n >= 1 and len(slots) >= n, 'invalid suffix multiplicity')
        lower = completion_factor(remaining, first, k)
        subset_rank, rank0 = divmod(rank - 1, lower)
        rank = rank0 + 1
        size = len(slots) - 1
        ones = n - 1
        require(subset_rank < math.comb(size, ones), 'subset rank too large')
        output[slots[-1]] = k + 1
        next_slots = []
        for index, position in enumerate(slots[:-1]):
            left = size - index
            count0 = math.comb(left - 1, ones) if ones <= left - 1 else 0
            if subset_rank < count0:
                next_slots.append(position)
            else:
                output[position] = k + 1
                subset_rank -= count0
                ones -= 1
                require(ones >= 0, 'too many selected month occurrences')
        require(ones == 0 and subset_rank == 0, 'subset combinadic residue')
        slots = next_slots
    for index in slots:
        output[index] = first + 1
    require(rank == 1 and all(output), 'suffix residual rank')
    for i in range(first, m):
        require(output.count(i+1) == remaining[i], 'suffix multiplicities')
    return output


def unrank_weave_at(lengths: list[int], one_based_rank: int, target_index: int,
                    *, full: bool = False) -> dict:
    """Return month ID and occurrence ordinal at zero-based calendar target.

    Lexicographic rank over actual month-ID words, not over WAT's intermediate
    rank or its compact suffix encoding. `full=True` checks all L positions.
    Each candidate block is independently counted as A(active_rem)*H[a][R].
    """
    total_length = sum(lengths)
    require(0 <= target_index < total_length, 'target outside year')
    rows = completion_table(lengths)
    require(1 <= one_based_rank <= rows[0][0], 'month weave rank outside family')
    m = len(lengths)
    remaining = [0] * m
    introduced = first = 0
    outstanding = 0
    factor = 1
    rank = one_based_rank
    consumed = [0] * m
    word = [] if full else None
    answer = None
    limit = total_length if full else target_index + 1

    for pos in range(limit):
        if introduced == m:
            # The final-month introduction ends the prefix selector. The
            # remaining rank now uses descending-month subset coordinates,
            # rather than chronological lexicographic next-symbol order.
            suffix = suffix_unrank_by_month_subsets(remaining, first, rank)
            require(len(suffix) == total_length - pos, 'suffix length mismatch')
            for j, month in enumerate(suffix[:limit-pos]):
                consumed[month - 1] += 1
                if full:
                    word.append(month)
                if pos + j == target_index:
                    answer = (month, consumed[month-1])
            if full:
                require(consumed == lengths, 'suffix completion count mismatch')
            return {'month_id': answer[0], 'day_in_month': answer[1],
                    'family_size': str(rows[0][0]),
                    'target_offset_zero_based': target_index,
                    'positions_verified': limit,
                    **({'word':word} if full else {})}
        require(outstanding == sum(remaining[first:introduced]), 'outstanding invariant')
        require(factor == completion_factor(remaining, first, introduced), 'completion factor invariant')
        expected = factor * rows[introduced][outstanding]
        require(1 <= rank <= expected, 'residual rank out of bounds')
        active = []
        prefix = 0
        for i in range(first, introduced):
            prefix += remaining[i]
            active.append((i, prefix))

        # Ratios for decrementing any one active month without recalculating
        # the huge multinomial factor from scratch for every alternative.
        tail_num = [1] * (introduced + 1)
        tail_den = [1] * (introduced + 1)
        for k in range(len(active) - 1, -1, -1):
            i, prefix_i = active[k]
            tail_num[i] = tail_num[i + 1] * (prefix_i - remaining[i])
            tail_den[i] = tail_den[i + 1] * (prefix_i - 1)
            # zero occurs only for first active month, and is never
            # included in a ratio for another earlier active month.

        choices: list[tuple[int, int, int]] = []  # (month index, block, next factor)
        if outstanding:
            for i, prefix_i in active:
                n = remaining[i]
                if n == 1 and i != first:  # premature final appearance
                    continue
                if n == 1:  # close the oldest active month
                    base_num, base_den = 1, 1
                else:
                    base_num, base_den = n - 1, prefix_i - 1
                numerator = factor * base_num * tail_num[i + 1]
                denominator = base_den * tail_den[i + 1]
                require(denominator > 0 and numerator % denominator == 0,
                        'nonintegral active suffix count')
                new_factor = numerator // denominator
                block = new_factor * rows[introduced][outstanding - 1]
                require(block > 0, 'empty active candidate')
                choices.append((i, block, new_factor))
        if introduced < m:
            q = lengths[introduced]
            new_factor = factor * math.comb(outstanding + q - 2, q - 2)
            block = new_factor * rows[introduced + 1][outstanding + q - 1]
            choices.append((introduced, block, new_factor))
        require(sum(c[1] for c in choices) == expected, 'block partition mismatch')
        selected = None
        for ident, block, next_factor in choices:
            if rank > block:
                rank -= block
            else:
                selected = (ident, next_factor)
                break
        require(selected is not None, 'unable to select month')
        ident, factor = selected
        if ident == introduced:
            remaining[ident] = lengths[ident] - 1
            outstanding += remaining[ident]
            introduced += 1
        else:
            remaining[ident] -= 1
            outstanding -= 1
            if remaining[ident] == 0:
                require(ident == first, 'month closure order')
                first += 1
        consumed[ident] += 1
        if full:
            word.append(ident + 1)
        if pos == target_index:
            answer = (ident + 1, consumed[ident])
    require(answer is not None, 'missing target answer')
    if full:
        require(first == m and introduced == m and outstanding == 0,
                'weave not exhausted')
        require(rank == 1 and consumed == lengths, 'final rank/length mismatch')
    return {'month_id':answer[0], 'day_in_month':answer[1],
            'family_size':str(rows[0][0]), 'target_offset_zero_based':target_index,
            'positions_verified':limit,
            **({'word':word} if full else {})}


def brute_words(lengths: list[int]) -> list[tuple[int, ...]]:
    m = len(lengths)
    all_words = set(itertools.permutations(
        tuple(i+1 for i, n in enumerate(lengths) for _ in range(n))))
    return sorted(w for w in all_words
                  if [w.index(i) for i in range(1,m+1)] == sorted(w.index(i) for i in range(1,m+1))
                  and [len(w)-1-w[::-1].index(i) for i in range(1,m+1)] == sorted(len(w)-1-w[::-1].index(i) for i in range(1,m+1)))


def selftest() -> None:
    for sizes in ([2,2], [2,2,2], [2,3,2], [3,2,2], [2,2,3]):
        valid = brute_words(sizes)
        require(len(valid) == completion_table(list(sizes))[0][0], 'brute cardinality mismatch')
        for rank, expected in enumerate(valid, 1):
            got = unrank_weave_at(list(sizes), rank, len(expected)-1, full=True)
            require(tuple(got['word']) == expected, 'lexicographic brute mismatch')
        for bad in (0, len(valid)+1):
            try:
                unrank_weave_at(list(sizes), bad, 0)
            except AssertionError:
                pass
            else:
                raise AssertionError('out-of-range rank should fail')
    print('WEAVE_SMALL_EXHAUSTIVE_PASS')


def audit_zip(zip_path: Path) -> dict:
    import stage02_calendar_trace_compositional_oracle as base
    actual_hash = hashlib.sha256(zip_path.read_bytes()).hexdigest()
    require(actual_hash == ZIP_SHA256, 'exact artifact ZIP checksum mismatch')
    with zipfile.ZipFile(zip_path) as z:
        require({'identity.txt','native-results.json','source.json','sha256.txt','instrumented.wasm'} <= set(z.namelist()),
                'incomplete trace ZIP')
        data = json.loads(z.read('native-results.json'))
        source = json.loads(z.read('source.json'))
        identity = z.read('identity.txt').decode('utf-8')
        require(data['project_id'] == PROJECT and data['source_blob'] == LOCKED_BLOB,
                'wrong project / original WAT blob')
        require(data['qa_sha'] == TRACE_SHA and int(data['run_id']) == TRACE_RUN and int(data['run_attempt']) == 1,
                'unmatched run/attempt/source SHA')
        for line in (f'PROJECT_ID={PROJECT}',f'SHA={TRACE_SHA}',f'RUN={TRACE_RUN}', 'ATTEMPT=1'):
            require(line in identity.splitlines(), 'identity sentinel mismatch')
        require(source['original_blob'] == LOCKED_BLOB and source['original_unchanged'],
                'modified original source')
        for line in z.read('sha256.txt').decode('utf-8').splitlines():
            digest, path = line.split(None, 1)
            member = path.strip().removeprefix('evidence/wat-calendar-trace/')
            if member in z.namelist():
                require(hashlib.sha256(z.read(member)).hexdigest() == digest,
                        f'checksum failure: {member}')
        require(hashlib.sha256(z.read('instrumented.wasm')).hexdigest() == data['wasm_sha256'],
                'WASM digest wrong')
        base.analyze(data, identity)  # independent earlier three date fields / selector events

        class CapturingTrace(base.Trace):
            def __init__(self, tc: dict):
                super().__init__(tc)
                self.weave_rank = None
            def pop(self, seal: int, **kw):
                got = super().pop(seal, **kw)
                if seal == 32:
                    self.weave_rank = got
                return got

        results = []
        for tc in data['cases']:
            tr = CapturingTrace(tc)
            year = base.find_year(tr)
            cutlet = base.derive_cutlet(tr,year)
            month = base.month_metadata(tr,cutlet['year_length'])
            require(tr.cursor == len(tr.entries) and tr.weave_rank is not None,
                    'unconsumed selectors / missing weaving rank')
            result = unrank_weave_at(month['month_lengths'], tr.weave_rank,
                                     cutlet['target_offset']-1,full=False)
            require(result['family_size'] == month['weaving_family_size'],
                    'weave count differs from independent baseline')
            independently_computed_name = month['month_names'][result['month_id']-1]
            expected_name, expected_day = tc['five_fields'][3:]
            require([independently_computed_name,result['day_in_month']] == [expected_name,expected_day],
                    f"{tc['case']}: independent month/day mismatch: "
                    f"{independently_computed_name},{result['day_in_month']} != {expected_name},{expected_day}")
            results.append({'case':tc['case'], 'independent_month_id':result['month_id'],
                            'independent_name':independently_computed_name,
                            'independent_day_in_month':result['day_in_month'],
                            'target_offset':result['target_offset_zero_based'],
                            'checked_prefix_positions':result['positions_verified'],
                            'five_fields_rederived':True})
    return {'project_id':PROJECT,'run_id':TRACE_RUN,'run_sha':TRACE_SHA,
            'zip_sha256':actual_hash,'checked_cases':len(results),
            'gate':'LOCAL_DIFFERENTIAL_FIVE_FIELDS_PASS','overall_stage02_accepted':False,
            'original_stage02_zip_manifest_verified':False,'cases':results}


def main() -> None:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('trace_zip', nargs='?',type=Path)
    p.add_argument('--selftest', action='store_true')
    a=p.parse_args()
    if a.selftest:
        selftest()
    if a.trace_zip:
        print(json.dumps(audit_zip(a.trace_zip),indent=2,ensure_ascii=False))
    elif not a.selftest:
        p.error('provide exact trace ZIP or --selftest')


if __name__=='__main__':
    try:
        main()
    except (AssertionError, ValueError, KeyError, zipfile.BadZipFile) as e:
        print('WEAVE_INDEPENDENT_ORACLE_FAIL: '+str(e),file=sys.stderr)
        raise SystemExit(1)
