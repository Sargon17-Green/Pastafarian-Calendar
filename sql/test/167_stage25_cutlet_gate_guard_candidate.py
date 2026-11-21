#!/usr/bin/env python3
"""QA-only outside-year exact-gate guard, with deterministic independent oracle."""
from __future__ import annotations

import argparse
import random
from pathlib import Path

SOURCE = Path('sql/20_stage02_cutlet_partition.sql')
OLD = ''' gate_at_day := pastafari_sql_tamil.exact_gate_index(p_calculation_day);
 IF gate_at_day IS NOT NULL AND
    gate_at_day > (p_year).open_gate_index AND
    gate_at_day < (p_year).close_gate_index THEN
   required_cut := (gate_at_day-(p_year).open_gate_index)::integer;
 END IF;'''
NEW = ''' -- Outside the target year's open/close days, no internal gate can match.
 -- The branch is explicit: do not evaluate costly exact_gate_index at all.
 IF p_calculation_day > (p_year).open_gate_day AND
    p_calculation_day < (p_year).close_gate_day THEN
   gate_at_day := pastafari_sql_tamil.exact_gate_index(p_calculation_day);
   IF gate_at_day IS NOT NULL AND
      gate_at_day > (p_year).open_gate_index AND
      gate_at_day < (p_year).close_gate_index THEN
     required_cut := (gate_at_day-(p_year).open_gate_index)::integer;
   END IF;
 END IF;'''


def transform(original: str) -> str:
    assert original.count(OLD) == 1, 'source lock: exact gate block must occur once'
    assert original.count('CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_cutlet_partition(') == 1
    candidate = original.replace(OLD, NEW, 1)
    assert candidate.replace(NEW, OLD, 1) == original
    assert candidate.count('exact_gate_index(p_calculation_day)') == 1
    return candidate


def self_test() -> None:
    """Independent set-membership oracle on strictly increasing gate-day series."""
    rng = random.Random(20261121)
    cases = 0
    bypass = 0
    for _ in range(500):
        open_index = rng.randint(-2000, 1000)
        n = rng.randint(6, 100)
        first = rng.randint(-100000, 100000)
        days = [first]
        for _ in range(n):
            days.append(days[-1] + rng.randint(1, 25))
        close_index = open_index + n
        index_by_day = {d: open_index + i for i, d in enumerate(days)}
        open_day, close_day = days[0], days[-1]
        queries = [open_day - 1, open_day, close_day, close_day + 1,
                   days[1], days[-2]]
        queries += [rng.randint(open_day - 250, close_day + 250) for _ in range(44)]
        for day in queries:
            # Original semantics: gate-index lookup, then internal-index condition.
            original_gate = index_by_day.get(day)
            original = (original_gate - open_index if original_gate is not None
                        and open_index < original_gate < close_index else None)
            # Independent oracle: enumerate internal gate days, no index lookup.
            expected = next((i for i, d in enumerate(days[1:-1], 1) if day == d), None)
            # Candidate: range guard before the exact index lookup.
            should_lookup = open_day < day < close_day
            guarded_gate = index_by_day.get(day) if should_lookup else None
            guarded = (guarded_gate - open_index if guarded_gate is not None
                       and open_index < guarded_gate < close_index else None)
            assert original == expected == guarded, (open_index, day)
            if not should_lookup:
                bypass += 1
            cases += 1
    assert cases == 25000 and bypass > 0
    stub = 'CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_cutlet_partition(\n' + OLD
    assert transform(stub).replace(NEW, OLD, 1) == stub
    for damaged in (stub.replace(OLD, ''), stub + OLD):
        try:
            transform(damaged)
        except AssertionError:
            pass
        else:
            raise AssertionError('transform accepted damaged source')
    print(f'SLICE25_GATE_GUARD_EQUIVALENCE={cases}/{cases} PASS')
    print(f'SLICE25_GATE_GUARD_BYPASSED_MODEL={bypass}/{cases}')
    print('SLICE25_GATE_GUARD_SOURCE_LOCK=PASS')
    print('SLICE25_GATE_GUARD_POSTGRESQL=NOT_EXECUTED')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--write-candidate', type=Path)
    args = parser.parse_args()
    if not (args.self_test or args.write_candidate):
        parser.error('must request --self-test and/or --write-candidate')
    if args.self_test:
        self_test()
    if args.write_candidate:
        candidate = transform(SOURCE.read_text(encoding='utf-8'))
        args.write_candidate.parent.mkdir(parents=True, exist_ok=True)
        args.write_candidate.write_text(candidate, encoding='utf-8')
        print('SLICE25_GATE_GUARD_TRANSFORM=EXACT_ONE_BLOCK STATIC_PASS')
        print('SLICE25_GATE_GUARD_PRODUCTION_SOURCE=UNCHANGED')


if __name__ == '__main__':
    main()
