#!/usr/bin/env python3
"""Independent, read-only Stage02 trace composition audit for WAT+Español.

Input: CI's wat-calendar-runtime-trace ZIP (not a repository fixture).
Output: JSON, or exit 1 on any discrepancy. Does not compile or modify WAT.
Scope: independently reconstruct year/cutlet/day-in-cutlet from ordered
selector events; inspect month naming/lengths, but not month weaving.
"""
from __future__ import annotations

import argparse
import hashlib
from functools import lru_cache
import json
import math
import sys
if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)  # exact large normative family counts
import zipfile
from dataclasses import dataclass
from pathlib import Path

PROJECT = 'PC-BRANCH-WAT-SPANISH'
ANCHOR = -15055671
M = (1 << 127) - 1
REQUIRED = (1, 10, 11, 12, 20, 21, 22, 30, 31, 32, 33)
LOCKED_SOURCE_BLOB = '70267bb5730678f81d6138a2224d6b8d9a193eb8'


def demand(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def rank_oracle(first: int, direction: int, n: int) -> tuple[int, int]:
    """Independent exact arithmetic based on the residue ring and rejection interval."""
    demand(1 <= first <= M and n > 0 and direction in (-1, 1), 'bad selector inputs')
    width, places = M, 1
    while width < n:
        width *= M
        places += 1
        demand(places <= 253, 'unsupported wide count')
    digits = [((first - 1 + j * direction) % M) for j in range(places)]
    value = 1 + sum(d * M**j for j, d in enumerate(digits))
    upper = width - width % n
    if value > upper:
        value = 1 if direction == 1 else upper
    return ((value - 1) % n) + 1, places


def unrank_distinct(master: int, k: int, rank: int) -> list[int]:
    """Factoradic unranking of k-permutations from labels 1..master."""
    demand(1 <= k <= master, 'invalid name count')
    universe = list(range(1, master + 1))
    demand(1 <= rank <= math.perm(master, k), 'name rank out of bounds')
    code = rank - 1
    result = []
    for pos in range(k):
        tail = math.perm(master - pos - 1, k - pos - 1)
        choice, code = divmod(code, tail)
        result.append(universe.pop(choice))
    demand(code == 0, 'permutation unrank remainder')
    return result


def count_compositions(rem: int, slots: int, cumulative: int, required: int, hit: bool) -> int:
    """Stars-and-bars using a forced internal cut if required>=0."""
    if slots == 0:
        return int(rem == 0 and (required < 0 or hit))
    if rem < slots:
        return 0
    if required < 0 or hit:
        return math.comb(rem - 1, slots - 1)
    local = required - cumulative
    if not 0 < local < rem or slots < 2:
        return 0
    return math.comb(rem - 2, slots - 2)


def unrank_partition(gates: int, parts: int, required: int, rank: int) -> list[int]:
    demand(1 <= rank <= count_compositions(gates, parts, 0, required, False), 'cutlet partition rank out of bounds')
    remain, cumulative, hit = gates, 0, False
    chosen = []
    for pos in range(parts):
        for width in range(1, remain - (parts - pos - 1) + 1):
            end = cumulative + width
            new_hit = hit or (required >= 0 and end == required)
            if required >= 0 and not hit and end > required:
                block = 0
            else:
                block = count_compositions(remain - width, parts - pos - 1, end, required, new_hit)
            if rank > block:
                rank -= block
                continue
            chosen.append(width)
            remain -= width
            cumulative = end
            hit = new_hit
            break
        else:
            raise AssertionError('composition unranking exhausted')
    demand(remain == 0 and (required < 0 or hit) and rank == 1, 'invalid cutlet partition')
    return chosen


@dataclass
class Year:
    number: int
    first_index: int
    last_index: int
    first_day: int
    last_day: int


class Trace:
    def __init__(self, tc: dict):
        self.case = tc['case']
        self.target = int(tc['target_day'])
        self.calculation = int(tc['calculation_day'])
        self.entries = tc['events']
        self.cursor = 0
        demand(self.calculation == ANCHOR, 'scope: trace calculation day must be foundation')

    def pop(self, seal: int, *, n: int | None = None, bowl: int | None = None) -> int:
        demand(self.cursor < len(self.entries), f'{self.case}: event underflow')
        ev = self.entries[self.cursor]
        self.cursor += 1
        demand(ev['seal'] == seal, f'{self.case}: expected seal {seal}, got {ev["seal"]} at event {self.cursor}')
        if n is not None:
            demand(int(ev['n']) == n, f'{self.case}: incorrect family cardinality for seal {seal}')
        if bowl is not None:
            demand(ev['bowl'] == bowl, f'{self.case}: unexpected bowl for seal {seal}')
        first, step, family = int(ev['first']), int(ev['direction']), int(ev['n'])
        independently, places = rank_oracle(first, step, family)
        demand(independently == int(ev['rank']) and places == ev['k'], f'{self.case}: rank oracle mismatch seal {seal}')
        return independently

    def gap(self) -> int:
        rank = self.pop(1, n=922, bowl=1)
        return 41 + rank


def initial_year(trace: Trace) -> Year:
    lower, upper = trace.calculation - 5778, trace.calculation + 5778
    demand(lower <= ANCHOR <= upper, 'foundation-crossing initial gate window only')
    negative = [(0, ANCHOR)]
    idx, day = 0, ANCHOR
    while day > lower:
        idx, day = idx - 1, day - trace.gap()
        negative.append((idx, day))
    gates = list(reversed(negative))
    idx, day = 0, ANCHOR
    while day < upper:
        idx, day = idx + 1, day + trace.gap()
        gates.append((idx, day))
    candidates = []
    for left in range(len(gates)):
        for right in range(left + 6, len(gates)):
            size = gates[right][1] - gates[left][1]
            if size > 5778:
                break
            if 252 <= size and gates[left][1] < trace.calculation <= gates[right][1]:
                candidates.append((size, gates[left], gates[right]))
    candidates.sort(key=lambda t: (t[0], t[1][1]))
    rank = trace.pop(10, n=len(candidates), bowl=1)
    _, start, end = candidates[rank - 1]
    return Year(5000, start[0], end[0], start[1], end[1])


def advance_year(trace: Trace, known: Year, forward: bool) -> Year:
    idx = known.last_index if forward else known.first_index
    day = known.last_day if forward else known.first_day
    anchor_idx, anchor_day = idx, day
    distance, steps = 0, 0
    candidates: list[tuple[int, int]] = []
    while True:
        gap = trace.gap()
        distance += gap
        steps += 1
        idx += 1 if forward else -1
        day += gap if forward else -gap
        if distance > 5778:
            break
        if steps >= 6 and distance >= 252:
            candidates.append((idx, day))
    chosen = candidates[trace.pop(11 if forward else 12, n=len(candidates), bowl=1) - 1]
    if forward:
        return Year(known.number + 1, anchor_idx, chosen[0], anchor_day, chosen[1])
    return Year(known.number - 1, chosen[0], anchor_idx, chosen[1], anchor_day)


def find_year(trace: Trace) -> Year:
    year = initial_year(trace)
    while trace.target > year.last_day:
        year = advance_year(trace, year, True)
    while trace.target <= year.first_day:
        year = advance_year(trace, year, False)
    demand(year.first_day < trace.target <= year.last_day, 'target outside year')
    return year


def derive_cutlet(trace: Trace, year: Year) -> dict:
    gates = year.last_index - year.first_index
    duration = year.last_day - year.first_day
    idx, day = year.first_index, year.first_day
    offsets = [0]
    forced_cut = -1
    for j in range(1, gates + 1):
        day += trace.gap()
        idx += 1
        offsets.append(day - year.first_day)
        if j < gates and day == trace.calculation:
            forced_cut = j
    demand(idx == year.last_index and day == year.last_day, 'gate reconstruction disagrees with year closing boundary')
    k_options = min(17, gates) - 5
    count = 5 + trace.pop(20, n=k_options, bowl=2)
    family_size = count_compositions(gates, count, 0, forced_cut, False)
    pieces = unrank_partition(gates, count, forced_cut, trace.pop(21, n=family_size, bowl=2))
    names = unrank_distinct(17, count, trace.pop(22, n=math.perm(17, count), bowl=5))
    position = trace.target - year.first_day
    cursor = 0
    for i, length_gates in enumerate(pieces):
        start = offsets[cursor]
        cursor += length_gates
        stop = offsets[cursor]
        if start < position <= stop:
            cutlet_name = names[i]
            day_in_cutlet = position - start
            break
    else:
        raise AssertionError('target cutlet not found')
    demand(cursor <= gates and sum(pieces) == gates, 'cutlet partition not exhaustive')
    return {'year':year.number,'cutlet':cutlet_name,'day_in_cutlet':day_in_cutlet,
            'year_length':duration,'gate_count':gates,'cutlet_count':count,
            'cutlet_partition':pieces,'names':names,'forced_cut':forced_cut,
            'target_offset':position}


def bounded_compositions_count(total: int, slots: int, low=4, high=123) -> int:
    shifted = total - slots*low
    if shifted < 0:
        return 0
    width = high-low+1
    return sum((-1)**j*math.comb(slots,j)*math.comb(shifted-j*width+slots-1,slots-1)
               for j in range(min(slots,shifted//width)+1))


@lru_cache(maxsize=20000)
def cached_bounded_count(total: int, slots: int) -> int:
    if slots == 0:
        return int(total == 0)
    if slots < 0 or not 4 * slots <= total <= 123 * slots:
        return 0
    return bounded_compositions_count(total, slots)


def unrank_month_lengths(length: int, count: int, rank: int) -> list[int]:
    """Lexicographic bounded-composition inverse, using inclusion/exclusion counts."""
    demand(1 <= rank <= cached_bounded_count(length, count), 'month length rank invalid')
    remaining = length
    answer = []
    for i in range(count):
        tail = count - i - 1
        for candidate in range(4, 124):
            block = cached_bounded_count(remaining - candidate, tail)
            if rank > block:
                rank -= block
                continue
            answer.append(candidate)
            remaining -= candidate
            break
        else:
            raise AssertionError('month length unrank failed')
    demand(remaining == 0 and rank == 1 and sum(answer) == length, 'length composition residue')
    return answer


def count_month_weavings(lengths: list[int]) -> int:
    """Exact combinatorial suffix DP; independent big integers, no WAT memory or fixtures."""
    remaining = sum(q - 1 for q in lengths)
    counts = [1] * (remaining + 1)
    for q in reversed(lengths):
        remaining -= q-1
        subtotal, coefficient = 0, 1
        new_counts = []
        for r in range(remaining + 1):
            subtotal += coefficient * counts[r + q - 1]
            new_counts.append(subtotal)
            coefficient = coefficient * (q + r - 1) // (r + 1)
        counts = new_counts
    demand(remaining == 0 and len(counts) == 1, 'suffix convolution completion')
    return counts[0]


def month_metadata(trace: Trace, length: int) -> dict:
    min_months = max(3, (length + 122)//123)
    max_months = min(47, length//4)
    count = min_months - 1 + trace.pop(30, n=max_months - min_months + 1, bowl=3)
    composition_count = cached_bounded_count(length, count)
    chosen_rank = trace.pop(31, n=composition_count, bowl=3)
    lengths = unrank_month_lengths(length, count, chosen_rank)
    weaving_count = count_month_weavings(lengths)
    # Exact independent family cardinality, but no rank-to-month weaving inverse yet.
    trace.pop(32, n=weaving_count, bowl=4)
    names = unrank_distinct(47, count, trace.pop(33, n=math.perm(47, count), bowl=5))
    return {'month_count':count,'composition_count':str(composition_count),
            'length_composition_rank':str(chosen_rank),
            'weaving_family_size':str(weaving_count),'month_lengths':lengths,
            'month_names':names,'month_weaving_independently_reconstructed':False}


def analyze(data: dict, identity: str) -> dict:
    demand(data['project_id'] == PROJECT and data['source_blob'] == LOCKED_SOURCE_BLOB, 'foreign project or WAT blob')
    demand(data['independent_rank_oracle'] and not data['independent_five_field_oracle'], 'unexpected declared oracle coverage')
    demand(not data['overall_stage02_accepted'] and not data['original_stage02_zip_manifest_verified'], 'unexpected stage/provenance status')
    coverage = data['trace_coverage']
    demand(coverage['required_seals'] == list(REQUIRED) and coverage['observed_seals'] == list(REQUIRED)
           and coverage['complete'] and not coverage['missing_seals'], 'incomplete callsite coverage')
    for field, expected in [('PROJECT_ID', PROJECT),('SHA', data['qa_sha']),('RUN', str(data['run_id'])),('ATTEMPT',str(data['run_attempt']))]:
        demand(f'{field}={expected}' in identity.splitlines(), f'identity mismatch {field}')
    reports = []
    for tc in data['cases']:
        trace = Trace(tc)
        year = find_year(trace)
        cutlet = derive_cutlet(trace, year)
        month = month_metadata(trace, cutlet['year_length'])
        demand(trace.cursor == len(trace.entries) == tc['trace_count'], f'{trace.case}: unconsumed events')
        observed = tc['five_fields']
        independent = [str(cutlet['year']),cutlet['cutlet'],cutlet['day_in_cutlet']]
        demand(independent == observed[:3], f'{trace.case}: first three fields disagree; expected {independent}, observed {observed[:3]}')
        demand(observed[3] in month['month_names'], 'month name not in permutation')
        month_id = month['month_names'].index(observed[3]) + 1
        demand(1 <= observed[4] <= month['month_lengths'][month_id-1], 'month-day exceeds independently computed month length')
        reports.append({'case':trace.case,'independent_first_three':independent,
                        'observed_five_fields':observed,'year_cutlet_gate_proof':cutlet,
                        'month_family_proof':{k:v for k,v in month.items() if k!='month_names'},
                        'observed_month_id_from_name':month['month_names'].index(observed[3])+1,
                        'independent_month_name':False,'independent_day_in_month':False,
                        'event_count':trace.cursor})
    return {'project_id':PROJECT,'source_sha':data['qa_sha'],'run_id':data['run_id'],
            'independent_fields':['year','cutlet','day_in_cutlet'],
            'not_yet_independent_fields':['month','day_in_month'],
            'stage02_accepted':False,'cases':reports}


def selftest() -> None:
    assert unrank_distinct(3,2,1) == [1,2]
    assert unrank_distinct(3,2,6) == [3,2]
    assert unrank_partition(5,3,-1,1) == [1,1,3]
    assert unrank_partition(5,3,2,1) == [1,1,3]
    assert count_compositions(5,3,0,-1,False) == 6
    assert count_compositions(5,3,0,2,False) == 3
    assert bounded_compositions_count(12,3) == 1
    assert bounded_compositions_count(13,3) == 3
    assert unrank_month_lengths(13,3,1) == [4,4,5]
    assert unrank_month_lengths(13,3,3) == [5,4,4]
    assert count_month_weavings([2,2,2]) > 0
    for n in [1,2,922,M-1,M,M+1,2*M,3*M]:
        for first in [1,2,M-1,M]:
            for direction in [-1,1]:
                got,_=rank_oracle(first,direction,n)
                assert 1 <= got <= n
    print('STATIC_SELFTEST_PASS',file=sys.stderr)


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact_zip', nargs='?',type=Path)
    parser.add_argument('--selftest',action='store_true')
    args=parser.parse_args()
    if args.selftest:
        selftest()
        if args.artifact_zip is None:
            return
    demand(args.artifact_zip is not None,'supply the exact CI ZIP artifact')
    with zipfile.ZipFile(args.artifact_zip) as z:
        names=set(z.namelist())
        demand({'identity.txt','native-results.json','source.json','sha256.txt','instrumented.wasm'}.issubset(names), 'incomplete ZIP contents')
        data=json.loads(z.read('native-results.json'))
        identity=z.read('identity.txt').decode('utf-8')
        source=json.loads(z.read('source.json'))
        demand(source['original_blob']==LOCKED_SOURCE_BLOB and source['original_unchanged'], 'unexpected instrumented source identity')
        sha=z.read('sha256.txt').decode('utf-8')
        for entry in sha.splitlines():
            digest,filename=entry.split(None,1)
            path=filename.strip().removeprefix('evidence/wat-calendar-trace/')
            if path in names:
                demand(hashlib.sha256(z.read(path)).hexdigest()==digest, 'artifact member checksum '+path)
        demand(hashlib.sha256(z.read('instrumented.wasm')).hexdigest()==data['wasm_sha256'], 'WASM checksum mismatch')
        result=analyze(data,identity)
    result['artifact_zip_sha256']=hashlib.sha256(args.artifact_zip.read_bytes()).hexdigest()
    print(json.dumps(result,indent=2,ensure_ascii=False))


if __name__=='__main__':
    try:
        main()
    except (AssertionError,KeyError,ValueError,zipfile.BadZipFile) as exc:
        print('COMPOSITIONAL_ORACLE_FAIL: '+str(exc),file=sys.stderr)
        raise SystemExit(1)