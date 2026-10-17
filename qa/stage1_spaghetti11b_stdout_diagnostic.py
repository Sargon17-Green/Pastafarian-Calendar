#!/usr/bin/env python3
"""QA11B forensic probe: obtain *partial* C++ stdout on bounded native mutant runs.

This is diagnostic only. No difference/timeout in this program means an
acceptance PASS. It intentionally writes all outcomes, including empty output.
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

OUTPUT = Path('spaghetti11b_partial_stdout_diagnostic.json')


def probe(label: str, source: bytes, seconds: int = 25) -> dict:
    with tempfile.TemporaryDirectory(prefix='qa11b_stdout_') as tempdir:
        file = Path(tempdir) / 'native.beq'
        file.write_bytes(source)
        # This is deliberately the same pinned Funge++ executable as normal.
        # stdbuf only changes the child process stdout buffering policy.
        args = ['stdbuf', '-o0', q10.ENGINE, '-fconcurrent',
                '-fthreads=funge', '-fno-execute', '-fno-filesystem', str(file)]
        started = time.monotonic()
        try:
            result = subprocess.run(args, input=b'1\n', capture_output=True, timeout=seconds)
            exit_code = result.returncode
            stdout, stderr = result.stdout, result.stderr
            timed_out = False
        except subprocess.TimeoutExpired as exc:
            exit_code = 124
            stdout, stderr = exc.stdout or b'', exc.stderr or b''
            timed_out = True
        values = []
        invalid = None
        for token in stdout.decode('ascii', errors='replace').split():
            if not re.fullmatch(r'-?\d+', token):
                invalid = token[:80]
                break
            values.append(int(token))
        entry = {
            'name': label, 'input_blob': q10.gitblob(source),
            'exit': exit_code, 'timeout': timed_out,
            'elapsed_seconds': round(time.monotonic() - started, 3),
            'stdout_bytes': len(stdout), 'stdout_sha256': hashlib.sha256(stdout).hexdigest(),
            'raw_prefix': repr(stdout[:160]), 'raw_suffix': repr(stdout[-160:]),
            'numbers': len(values), 'first_numbers': values[:22],
            'last_numbers': values[-8:], 'invalid_first_token': invalid,
            'stderr_tail': stderr.decode('utf-8', 'replace')[-250:],
        }
        print('QA11B_STDOUT_FORENSIC', label, 'rc', exit_code,
              'bytes', len(stdout), 'nums', len(values),
              'prefix', values[:8], 'elapsed', entry['elapsed_seconds'], flush=True)
        return entry


def main():
    raw = full.SOURCE.read_bytes()
    manifest = json.loads(full.MANIFEST.read_text('utf-8'))
    full.verify_source(raw, manifest)
    selected = [
        ('healthy_early', raw),
        ('axis01', full.axis_mutation(raw, manifest['stages'][0])),
        ('axis09', full.axis_mutation(raw, manifest['stages'][8])),
        ('role_multiply', full.role_mutation(raw, manifest['stages'][7],
                          manifest['cross_residual_formula'], 42, 43)),
        ('workerC_21', q11.mutate_worker_divider(raw)),
    ]
    receipt = {'schema': 'qa11b-native-partial-stdout-forensics-v1',
               'engine_git_commit': manifest['engine_commit'],
               'source_blob': q10.gitblob(raw), 'sampling_seconds_per_case': 25,
               'acceptance': 'NOT_APPLICABLE', 'runs': []}
    try:
        for label, source in selected:
            receipt['runs'].append(probe(label, source))
            OUTPUT.write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
    finally:
        OUTPUT.write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
    print('QA11B_DIAGNOSTIC_COMPLETE_NOT_ACCEPTANCE', flush=True)


if __name__ == '__main__':
    main()