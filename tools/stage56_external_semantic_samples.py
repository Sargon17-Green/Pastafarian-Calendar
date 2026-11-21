#!/usr/bin/env python3
"""QA-only tuples from pinned external Python engine, never a PHP production export."""
from __future__ import annotations
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

PROJECT = 'PC-BRANCH-PHP-MALAY'
PROVIDER = 'implementations/python/pastafari_calendar/core.py'
CANONICAL_SHA = 'cc2cf0b422757a5e7c33218ce30cffa8f99c6786'

def fail(message: str) -> None:
    raise ValueError(message)

def git(root: Path, *args: str) -> str:
    return subprocess.check_output(['git', '-C', str(root), *args], stderr=subprocess.PIPE).decode().strip()

def offsets(record: dict) -> list[int]:
    weaving = record['month_weaving']
    n = len(weaving)
    seen_first, seen_last = {}, {}
    for i, month in enumerate(weaving):
        seen_first.setdefault(month, i)
        seen_last[month] = i
    choices = {0, 1, n - 2, n - 1}
    choices.update((n - 1) * fraction // 8 for fraction in range(1, 8))
    choices.update(seen_first.values())
    choices.update(seen_last.values())
    return sorted(choices)

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--canonical-repo', type=Path, required=True)
    ap.add_argument('--input', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    args = ap.parse_args()
    root = args.canonical_repo.resolve(strict=True)
    data = json.loads(args.input.read_bytes())
    source = data['source']
    if data.get('project_id') != PROJECT or data.get('status') != 'EXTERNAL_REFERENCE_NOT_PHP_PROVIDER':
        fail('unexpected project or source kind')
    if source.get('kind') != 'external_canonical_reference' or source.get('source_commit') != CANONICAL_SHA:
        fail('external reference provenance mismatch')
    if git(root, 'rev-parse', 'HEAD') != CANONICAL_SHA or git(root, 'status', '--porcelain', '--untracked-files=all'):
        fail('external source checkout is not exact and clean')
    source_bytes = (root / PROVIDER).read_bytes()
    if source_bytes != subprocess.check_output(['git', '-C', str(root), 'show', f'{CANONICAL_SHA}:{PROVIDER}']):
        fail('python execution bytes differ from Git')
    if source['provider']['sha256'] != hashlib.sha256(source_bytes).hexdigest():
        fail('python source digest mismatch')
    spec = importlib.util.spec_from_file_location('external_stage56_semantic_core', root / PROVIDER)
    if spec is None or spec.loader is None:
        fail('python source cannot load')
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    jdn = data['calculation_jdn']
    state = mod.CalculationState(jdn)
    anchor = state.get_year_5000()
    years = [state.previous_year(anchor), anchor, state.next_year(anchor)]
    result = []
    for record, year in zip(data['years'], years):
        if record['number'] != year.number or record['open_gate_day'] != year.start_jdn - 1 or record['close_gate_day'] != year.end_jdn:
            fail('external Python year differs from previously exported record')
        year_samples = []
        for offset in offsets(record):
            target_jdn = year.start_jdn + offset
            date = state.convert(target_jdn)
            year_samples.append({
                'jdn': target_jdn,
                'tuple': {
                    'year': str(date.year),
                    'cutletName': date.cutlet_name,
                    'dayInCutlet': date.day_in_cutlet,
                    'monthName': date.month_name,
                    'dayInMonth': date.day_in_month,
                },
            })
        result.append({'year': year.number, 'samples': year_samples})
    output = {'project_id': PROJECT, 'status': 'EXTERNAL_PYTHON_QA_ONLY', 'source_commit': CANONICAL_SHA,
              'calculation_jdn': jdn, 'years': result}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    blob = (json.dumps(output, sort_keys=True, ensure_ascii=False, separators=(',', ':')) + '\n').encode('utf-8')
    args.output.write_bytes(blob)
    args.output.with_suffix(args.output.suffix + '.sha256').write_text(
        hashlib.sha256(blob).hexdigest() + '  ' + args.output.name + '\n', encoding='utf-8'
    )
    print(json.dumps({'status': 'EXTERNAL_PYTHON_QA_ONLY', 'samples': sum(len(y['samples']) for y in result),
                      'sha256': hashlib.sha256(blob).hexdigest()}, sort_keys=True))

if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as exc:
        print(f'STAGE56_EXTERNAL_SAMPLE_REJECTED: {exc}', file=sys.stderr)
        raise SystemExit(2)
