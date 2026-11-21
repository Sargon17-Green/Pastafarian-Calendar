#!/usr/bin/env python3
"""Bounded source-grounded census for *actual* 45-month normative years.

Stage1 QA ONLY, not a normative 45-month interleaving acceptance test.

Inputs: the exact pinned independent normative_reference.py blob; calculation
context FOUNDATION_DAY; 1..8 consecutive years starting with year 5000.
Outputs: durable JSON census with exact year gates, month counts, and, if an
actual 45-month year occurs, its independently selected normative month lengths.
Does not construct any month weaving, invoke Fortran, or claim an accepted date.

Next gate (separate): verify full 45-color actual month-weaving semantics and
end-to-end five-field dates against original Fortran with explicit 65s/case
limits, independent source review, and saved JSON/log/artifact evidence.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

PROJECT_ID = 'PC-BRANCH-FORTRAN-ENGLISH'
FOUNDATION = -15055671
REFERENCE_BLOB = 'd58298c6b7be58fc1d1e2d64a0d203b7c42e4d53'
MAX_SURVEY_YEARS = 8
DEFAULT_OUTPUT = Path('build/stage01-actual-45-preflight.json')


def ensure(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(b'blob ' + str(len(data)).encode('ascii') + b'\0' + data).hexdigest()


def month_bounds(length: int) -> tuple[int, int]:
    ensure(252 <= length <= 5778, 'invalid actual year length')
    return (length + 122) // 123, min(47, length // 4)


def validated_month_selection(length: int, selected: int) -> tuple[int, int]:
    lo, hi = month_bounds(length)
    ensure(3 <= lo <= selected <= hi <= 47, 'month selection outside normative bounds')
    return lo, hi


def load_reference(path: Path):
    data = path.read_bytes()
    ensure(git_blob_sha(data) == REFERENCE_BLOB, 'pinned reference blob mismatch')
    spec = importlib.util.spec_from_file_location('stage01_actual_45_pinned', path)
    ensure(spec is not None and spec.loader is not None, 'reference loader unavailable')
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    ensure(module.FOUNDATION_DAY == FOUNDATION, 'reference foundation mismatch')
    ensure(module.MIN_MONTH_DAYS == 4 and module.MAX_MONTH_DAYS == 123,
           'reference month-length contract changed')
    ensure(module.MAX_MONTHS == 47, 'reference month-count contract changed')
    return module.NormativeCalendar()


def save(path: Path, result: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n',
                         encoding='utf-8')
    temporary.replace(path)


def run(reference: Path, maximum: int, output: Path) -> int:
    ensure(1 <= maximum <= MAX_SURVEY_YEARS, 'max-years must be 1..8')
    record = {
        'project_id': PROJECT_ID,
        'reference_blob': REFERENCE_BLOB,
        'calculation_day': FOUNDATION,
        'max_years': maximum,
        'year_census': [],
        'actual_45_month_candidate_found': False,
        'full_stage1_accepted': False,
        'actual_45_month_interleaving_accepted': False,
        'status': 'in_progress',
    }
    save(output, record)
    try:
        oracle = load_reference(reference)
        year = oracle.year5000(FOUNDATION)
        for index in range(maximum):
            if index:
                year = oracle.next_year(FOUNDATION, year)
            length = year.close_gate_day - year.open_gate_day
            ensure(year.number == 5000 + index, 'non-consecutive year numbering')
            ensure(year.open_gate_day < year.close_gate_day, 'reversed gates')
            # Same pinned normative Python functions as the reference's
            # build_year_structure, but intentionally stop *before* weaving.
            sauce = oracle._sauce(FOUNDATION, year.open_gate_day + 1)
            selected = oracle.choose_month_count(sauce, year)
            minimum, maximum = validated_month_selection(length, selected)
            entry = {
                'year_number': year.number,
                'open_gate_day': year.open_gate_day,
                'close_gate_day': year.close_gate_day,
                'year_days': length,
                'min_month_count': minimum,
                'max_month_count': maximum,
                'actual_month_count': selected,
                'has_45_actual_months': selected == 45,
                'actual_weaving_materialized': False,
            }
            if selected == 45:
                lengths = tuple(oracle.choose_month_lengths(sauce, year, selected))
                ensure(len(lengths) == 45 and sum(lengths) == length,
                       'actual 45-month lengths do not partition the year')
                ensure(all(4 <= n <= 123 for n in lengths),
                       'actual month lengths outside bounds')
                entry['actual_month_lengths'] = list(lengths)
                record['actual_45_month_candidate_found'] = True
            record['year_census'].append(entry)
            save(output, record)
            print('STAGE01_ACTUAL_45_CENSUS_YEAR=' + str(year.number) +
                  ' MONTHS=' + str(selected) + ' DAYS=' + str(length), flush=True)
        record['status'] = 'completed_preflight_only'
        save(output, record)
        print('STAGE01_ACTUAL_45_PREFLIGHT=' + str(maximum) + '/' + str(maximum))
        print('STAGE01_ACTUAL_45_CANDIDATE_FOUND=' +
              str(record['actual_45_month_candidate_found']).lower())
        print('STAGE01_ACTUAL_45_NOT_INTERLEAVING_ACCEPTANCE')
        return 0
    except Exception as exc:
        record['status'] = 'error'
        record['error'] = type(exc).__name__ + ': ' + str(exc)
        save(output, record)
        raise


def self_test() -> int:
    ensure(git_blob_sha(b'abc') == 'f2ba8f84ab5c1bce84a7b441cb1959cfc7093b7f',
           'blob hash regression')
    ensure(month_bounds(252) == (3, 47), 'small year bounds')
    ensure(month_bounds(5778) == (47, 47), 'large year bounds')
    ensure(validated_month_selection(252, 45) == (3, 47), 'eligible selection')
    try:
        validated_month_selection(5778, 45)
    except AssertionError:
        pass
    else:
        raise AssertionError('invalid 45-month selection accepted')
    print('STAGE01_ACTUAL_45_PREFLIGHT_SELFTEST=5/5')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path)
    parser.add_argument('--max-years', type=int, default=4)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    ensure(args.reference is not None, '--reference is required')
    return run(args.reference, args.max_years, args.output)


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as exc:
        print('STAGE01_ACTUAL_45_PREFLIGHT_ERROR=' + repr(exc), file=sys.stderr)
        sys.exit(1)
