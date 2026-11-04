#!/usr/bin/env python3
"""Run every selector WAT export in a fresh WasmKit process, fail closed.

Usage:
    python3 tests/run_stage02_discovery01_native.py [--json-out results.json]

Requires: Python 3.9+ and `wasmkit` 0.1.6 on PATH.
No Git checkout, dependency installation or automatic file mutation occurs.
"""
import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json-out', type=Path, help='Optional JSON evidence output path')
    parser.add_argument('--timeout', type=float, default=30.0)
    args = parser.parse_args()
    source = Path(__file__).with_name('normative_selector.wat')
    if args.timeout <= 0:
        parser.error('--timeout must be positive')
    if not source.is_file():
        print(f'MISSING_SOURCE: {source}', file=sys.stderr)
        return 2
    tests = re.findall(r'\(func \(export "([^"]+)"\)', source.read_text(encoding='utf-8'))
    if len(tests) != 29 or len(set(tests)) != 29:
        print(f'WRONG_TEST_SET: expected 29 unique exports, got {len(tests)}', file=sys.stderr)
        return 2
    outcomes = []
    for name in tests:
        t0 = time.monotonic()
        try:
            p = subprocess.run(['wasmkit', 'run', str(source), name], capture_output=True,
                               text=True, timeout=args.timeout, check=False)
            outcome = {'export': name, 'exit': p.returncode, 'stdout': p.stdout,
                       'stderr': p.stderr, 'timeout': False}
        except subprocess.TimeoutExpired as err:
            outcome = {'export': name, 'exit': None, 'stdout': str(err.stdout),
                       'stderr': str(err.stderr), 'timeout': True}
        except FileNotFoundError:
            print('MISSING_RUNTIME: wasmkit not found on PATH', file=sys.stderr)
            return 2
        outcome['seconds'] = round(time.monotonic() - t0, 4)
        outcome['pass'] = (outcome['exit'] == 0 and outcome['stdout'] ==
                           '[WasmTypes.Value.i32(1)]\n' and outcome['stderr'] == ''
                           and not outcome['timeout'])
        outcomes.append(outcome)
        print(('PASS ' if outcome['pass'] else 'FAIL ') + name)
    payload = {'source_path': str(source), 'executions': len(outcomes),
               'passed': sum(c['pass'] for c in outcomes), 'results': outcomes}
    if args.json_out:
        args.json_out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n',
                                 encoding='utf-8')
    print(f"WASM_NATIVE {payload['passed']}/{payload['executions']}")
    return 0 if payload['passed'] == len(outcomes) else 1


if __name__ == '__main__':
    sys.exit(main())
