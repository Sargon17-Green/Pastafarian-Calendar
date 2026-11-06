#!/usr/bin/env python3
"""Three additional original Fortran/Python five-field comparisons for Stage 1.

The independent Python algorithm is loaded only from a SHA-pinned normative
source; it is never copied into or implemented by the Fortran branch. Target
selection uses fixed interior offsets from previously independently verified
year-boundary witnesses, not candidate output. This is NOT full Stage1 acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import resource
import subprocess
import sys
from pathlib import Path

PROJECT_ID = 'PC-BRANCH-FORTRAN-ENGLISH'
PYTHON_COMMIT = '0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4'
PYTHON_BLOB = 'd58298c6b7be58fc1d1e2d64a0d203b7c42e4d53'
CALCULATION_DAY = -15055671
# Independent year-end witnesses (already compared against pinned Python):
# last of 4999 = -15057703; first of 5001 = -15053458.
# Offsets 137, 271, 137 target interior days, not the seven old cases.
TARGETS = (-15057703 - 137, CALCULATION_DAY + 271, -15053458 + 137)
YEARS = (4999, 5000, 5001)
FIELDS = ('year_number', 'cutlet_name_index', 'day_in_cutlet',
          'month_name_index', 'day_in_month')
REFERENCE_TIMEOUT = 60
FORTRAN_TIMEOUT = 45


def verify_reference(path: Path) -> None:
    contents = path.read_bytes()
    digest = hashlib.sha1(b'blob ' + str(len(contents)).encode() + b'\0' + contents).hexdigest()
    if digest != PYTHON_BLOB:
        raise ValueError('Pinned Python normative blob SHA mismatch: ' + digest)


def extract_five(stdout: str, prefix: str) -> tuple[int, ...]:
    entries = [line[len(prefix):] for line in stdout.splitlines() if line.startswith(prefix)]
    if len(entries) != 1:
        raise ValueError('Missing/duplicate exact five-field output: ' + prefix)
    components = entries[0].split(',')
    if len(components) != 5:
        raise ValueError('Expected exactly five numeric fields')
    return tuple(int(x) for x in components)


def bounded(command: list[str], seconds: int, memory_mib: int) -> str:
    def limit_memory() -> None:
        size = memory_mib * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (size, size))
    result = subprocess.run(command, capture_output=True, text=True,
                            timeout=seconds, check=False, preexec_fn=limit_memory)
    if result.returncode != 0:
        raise RuntimeError(f'exit={result.returncode}; stdout={result.stdout[-900:]}; '
                           f'stderr={result.stderr[-900:]}')
    return result.stdout


def reference_worker(path: Path, target: int) -> int:
    verify_reference(path)
    spec = importlib.util.spec_from_file_location('pinned_stage01_date_reference', path)
    if spec is None or spec.loader is None:
        raise RuntimeError('Cannot load pinned independent Python reference')
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    result = module.NormativeCalendar().calendar_date_ids(CALCULATION_DAY, target)
    values = [int(getattr(result, key)) for key in FIELDS]
    print('STAGE01_EXPANDED_ORACLE_FIELDS=' + ','.join(map(str, values)), flush=True)
    return 0


def self_test() -> int:
    tests = (
        len(TARGETS) == 3,
        len(set(TARGETS)) == 3,
        TARGETS[0] < -15057703 < TARGETS[1] < -15053458 < TARGETS[2],
        extract_five('STAGE01_EXPANDED_FIELDS=4999,15,433,32,121',
                     'STAGE01_EXPANDED_FIELDS=') == (4999, 15, 433, 32, 121),
        len(FIELDS) == 5,
    )
    assert all(tests)
    try:
        extract_five('STAGE01_EXPANDED_FIELDS=1,2,3,4', 'STAGE01_EXPANDED_FIELDS=')
    except ValueError:
        pass
    else:
        raise AssertionError('Malformed field count was accepted')
    print('STAGE01_EXPANDED_HARNESS_UNIT_ASSERTIONS=6/6')
    return 0


def compare(reference: Path, fortran: Path) -> int:
    verify_reference(reference)
    rows = []
    for case, (target, year) in enumerate(zip(TARGETS, YEARS), 1):
        row = {'case': case, 'calculation_day': CALCULATION_DAY,
               'target_day': target, 'expected_year': year, 'status': 'error'}
        try:
            ref_stdout = bounded([sys.executable, '-u', str(Path(__file__).resolve()),
                                  '--worker', str(target), '--reference', str(reference)],
                                 REFERENCE_TIMEOUT, 1536)
            expected = extract_five(ref_stdout, 'STAGE01_EXPANDED_ORACLE_FIELDS=')
            if expected[0] != year:
                raise ValueError(f'Independent reference year {expected[0]} != {year}')
            native_stdout = bounded([str(fortran.resolve()), str(target)],
                                    FORTRAN_TIMEOUT, 1024)
            if native_stdout.splitlines().count(f'STAGE01_EXPANDED_TARGET={target}') != 1:
                raise ValueError('Original Fortran did not confirm exact input target')
            actual = extract_five(native_stdout, 'STAGE01_EXPANDED_FIELDS=')
            differences = [{'field': field, 'python': x, 'fortran': y}
                           for field, x, y in zip(FIELDS, expected, actual) if x != y]
            row.update(python=dict(zip(FIELDS, expected)),
                       fortran=dict(zip(FIELDS, actual)), differences=differences,
                       matched_fields=5 - len(differences),
                       status='match' if not differences else 'mismatch')
        except Exception as exc:
            row['error'] = repr(exc)
            row['matched_fields'] = 0
        rows.append(row)
        print(f"STAGE01_EXPANDED_CASE={case} TARGET={target} "
              f"STATUS={row['status']} MATCHED_FIELDS={row['matched_fields']}/5", flush=True)
    matched_cases = sum(row['status'] == 'match' for row in rows)
    matched_fields = sum(row['matched_fields'] for row in rows)
    report = {'project_id': PROJECT_ID, 'reference_commit': PYTHON_COMMIT,
              'reference_blob': PYTHON_BLOB, 'calculation_day': CALCULATION_DAY,
              'targets': list(TARGETS), 'candidate_only': False,
              'original_normative_fortran': True, 'full_stage1_accepted': False,
              'limits_seconds': {'python': REFERENCE_TIMEOUT, 'fortran': FORTRAN_TIMEOUT},
              'matched_cases': matched_cases, 'total_cases': 3,
              'matched_fields': matched_fields, 'total_fields': 15, 'results': rows}
    Path('stage01_expanded_real_date_diff.json').write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    if matched_cases == 3 and matched_fields == 15:
        print('STAGE01_EXPANDED_REAL_DATE_DIFFERENTIAL=3/3 CASES; 15/15 EXACT FIELDS')
        print('STAGE01_EXPANDED_DIFF_PASS_ONLY_NOT_FULL_STAGE1_ACCEPTANCE')
        return 0
    print(f'STAGE01_EXPANDED_DIFF_NOT_ACCEPTED={matched_cases}/3; {matched_fields}/15')
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--reference', type=Path)
    parser.add_argument('--fortran-exe', type=Path)
    parser.add_argument('--worker', type=int)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if args.reference is None:
        parser.error('--reference is required')
    if args.worker is not None:
        return reference_worker(args.reference, args.worker)
    if args.fortran_exe is None:
        parser.error('--fortran-exe is required')
    return compare(args.reference, args.fortran_exe)


if __name__ == '__main__':
    sys.exit(main())
