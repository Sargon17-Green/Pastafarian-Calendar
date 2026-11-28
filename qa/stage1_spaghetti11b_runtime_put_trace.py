#!/usr/bin/env python3
"""QA11B non-acceptance forensic: record actual Funge p writes into 208 17D cells.

Only the disposable CI interpreter is instrumented. This test deliberately does not
turn a timeout, a changed printed residue, or malformed future code into PASS.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import tempfile
import time
from pathlib import Path

import stage1_spaghetti10_macro_native as q10
import stage1_spaghetti11b_three_shard_native as q11
import stage1_spaghetti11b_full_native as full

SOURCE = Path('qa/spaghetti11_17d_cascade_208_generated_candidate.beq')
MANIFEST = Path('qa/SPAGHETTI11B_THIRD_RESIDUE_MACRO_MANIFEST.json')
TARGET = Path('spaghetti11b_runtime_put_trace_receipt.json')
TRACE = re.compile(r'^QA11B_RUNTIME_PUT:([-0-9:]+):(-?\d+)$', re.M)


def native(source: bytes, seed: int, timeout: int = 205) -> dict:
    with tempfile.TemporaryDirectory(prefix='qa11b_puts_') as folder:
        path = Path(folder) / 'probe.beq'
        path.write_bytes(source)
        cmd = [q10.ENGINE, '-fconcurrent', '-fthreads=funge',
               '-fno-execute', '-fno-filesystem', str(path)]
        start = time.monotonic()
        try:
            completed = subprocess.run(cmd, input=f'{seed}\n'.encode(),
                                       capture_output=True, timeout=timeout)
            stdout, stderr, code = completed.stdout, completed.stderr, completed.returncode
        except subprocess.TimeoutExpired as exc:
            stdout, stderr, code = exc.stdout or b'', exc.stderr or b'', 124
        stdout = stdout.decode('utf8', 'replace')
        stderr = stderr.decode('utf8', 'replace')
        try:
            numbers = [int(x) for x in stdout.split()]
        except ValueError:
            numbers = []
        writes = []
        for found in TRACE.finditer(stderr):
            coordinates = tuple(map(int, found[1].split(':')))
            if len(coordinates) == 17:
                writes.append({'coordinate': coordinates, 'value': int(found[2])})
        return {'exit': code, 'elapsed': round(time.monotonic() - start, 3),
                'stdout_prefix': numbers[:24], 'stdout_count': len(numbers),
                'stdout_bytes': len(stdout.encode()),
                'stderr_tail': stderr[-750:], 'write_count': len(writes),
                'writes': writes}


def main():
    original = SOURCE.read_bytes()
    meta = json.loads(MANIFEST.read_text('utf8'))
    full.verify_source(original, meta)
    steps = meta['stages']
    target_coords = {tuple(c) for st in steps for c in st['target_positions']}
    assert len(target_coords) == 208
    receipt = {'schema': 'qa11b-actual-runtime-put-forensic-v1',
               'head_source_blob': q10.gitblob(original),
               'input_manifest_sha256': hashlib.sha256(MANIFEST.read_bytes()).hexdigest(),
               'not_full_qa11b_acceptance': True,
               'cases': [], 'diagnostic_completed': False}
    try:
        def one(label, source, seed=1, timeout=205):
            run = native(source, seed, timeout)
            targeted = [x for x in run['writes'] if tuple(x['coordinate']) in target_coords]
            foreign = run['write_count'] - len(targeted)
            assert foreign == 0, f'trace includes {foreign} out-of-target writes'
            mapping = {}
            for item in targeted:
                pos = tuple(item['coordinate'])
                mapping.setdefault(pos, []).append(item['value'])
            result = {'name': label, 'seed': seed, 'rc': run['exit'],
                      'elapsed_seconds': run['elapsed'],
                      'stdout_count': run['stdout_count'],
                      'stdout_prefix': run['stdout_prefix'],
                      'stdout_bytes': run['stdout_bytes'],
                      'physical_target_write_count': len(targeted),
                      'unique_target_cells': len(mapping),
                      'repeat_target_writes': {str(k): v for k, v in mapping.items() if len(v) > 1},
                      'first_writes': targeted[:6],
                      'last_writes': targeted[-4:],
                      'stderr_tail': run['stderr_tail']}
            receipt['cases'].append(result)
            print('QA11B_RUNTIME_PUT_TRACE', label, 'rc', run['exit'],
                  'target_p', len(targeted), 'stdout', run['stdout_count'],
                  'seconds', run['elapsed'], flush=True)
            return result, {k: v[-1] for k, v in mapping.items()}

        base, base_map = one('healthy', original, timeout=250)
        base['expected_228_numbers'] = base['rc'] == 0 and base['stdout_count'] == 228
        base['all_208_written'] = len(base_map) == 208
        if not base['all_208_written']:
            print('QA11B_RUNTIME_PUT_BASELINE_INCOMPLETE', len(base_map), flush=True)
        third = q11.mutate_worker_divider(original)
        changes = [
            ('third_worker_residue_21', third, 1),
            ('axis_01', full.axis_mutation(original, steps[0]), 1),
            ('axis_09', full.axis_mutation(original, steps[8]), 9),
            ('axis_16', full.axis_mutation(original, steps[15]), 16),
            ('opcode_multiply_axis08', full.role_mutation(
                original, steps[7], meta['cross_residual_formula'], 42, 43), 8),
        ]
        for label, source, focus in changes:
            report, changed = one(label, source)
            coords = {tuple(c) for c in steps[focus-1]['target_positions']}
            diffs = [{'coordinate': c, 'healthy': base_map[c], 'mutated': val}
                     for c, val in changed.items() if c in coords and c in base_map
                     and val != base_map[c]]
            report['focus_axis'] = focus
            report['focus_axis_mutant_writes'] = len(set(changed) & coords)
            report['focus_axis_changed_writes'] = len(diffs)
            report['focus_axis_first_changed'] = diffs[:6]
            report['real_opcode_value_change_proven'] = len(diffs) > 0
            print('QA11B_RUNTIME_PUT_CAUSAL', label,
                  'PROVEN' if diffs else 'NOT_PROVEN', len(diffs), flush=True)
        receipt['diagnostic_completed'] = True
    finally:
        TARGET.write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n',
                          encoding='utf8')
    print('QA11B_RUNTIME_PUT_DIAGNOSTIC_COMPLETE_NOT_ACCEPTANCE', flush=True)


if __name__ == '__main__':
    main()