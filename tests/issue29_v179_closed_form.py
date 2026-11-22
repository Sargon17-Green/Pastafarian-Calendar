#!/usr/bin/env python3
"""Independent two-month combinatorial formula, versus source-locked Ada GMP.

No original calendar converter, month-name selection, or F(c,t) is imported.
"""
from __future__ import annotations
from pathlib import Path
import hashlib
import json
import math
import os
import re
import resource
import signal
import subprocess
import sys
import time

BASE = '1160096aa847c54cbef27c232771ce1549d7ba8f'
SOURCE_BASE = 'e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN = '56bc4173aae4975ded019ef5ab5a36249f1424df'
README_BLOB = '74c424b44eadd4ece3f29072ddbf873236557604'
BRANCH = 'qa/issue29-ada-gmp-two-month-closed-form-v179'
ACTIVATION = 'ci(issue29-v179): closed-form full two-month grid vs GMP; zero calendar F'
SOURCE_BLOBS = {
 'src/canonical_full_weave_gmp_v164.adb':'845bd8905943a54e63d6aba0334404a5051fe666',
 'src/canonical_full_weave_gmp_v164.ads':'0b68edf7eddbc33869358bcfcc21e32465fc591e',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
ALLOWED = {
 '.github/workflows/issue29-v179-two-month-closed-form.yml',
 'issue29_v179_two_month_closed_form.gpr',
 'tests/issue29_v179_two_month_closed_form_tests.adb',
 'tests/issue29_v179_closed_form.py',
}
EV = Path('evidence')
REF = EV / 'v179-two-month-reference.dat'
BIN = Path('bin_v179/issue29_v179_two_month_closed_form_tests')
GRID_N = 122 * 122
SCHEMA = 'ISSUE29_V179_INDEPENDENT_TWO_MONTH_BINOMIAL_NO_CALENDAR_F/1'
BOUNDARIES = {2, 3, 4, 47, 64, 89, 123}

def require(cond: bool, message: str) -> None:
    if not cond:
        raise ValueError(message)

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def git_blob(data: bytes) -> str:
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], stderr=subprocess.DEVNULL).decode().strip()

def write_once(path: Path, data: bytes) -> None:
    with path.open('xb') as out:
        out.write(data)
        out.flush()
        os.fsync(out.fileno())

def write_json(path: Path, data: dict) -> None:
    write_once(path, (json.dumps(data, sort_keys=True, indent=2) + '\n').encode())

def identity() -> dict:
    require(os.environ.get('GITHUB_EVENT_NAME') == 'push', 'push event only')
    require(os.environ.get('GITHUB_RUN_ATTEMPT') == '1', 'rerun forbidden')
    require(os.environ.get('GITHUB_REF') == 'refs/heads/' + BRANCH, 'incorrect QA branch')
    event_path = os.environ.get('GITHUB_EVENT_PATH', '')
    require(bool(event_path) and Path(event_path).is_file(), 'event missing')
    event = json.loads(Path(event_path).read_bytes())
    require(event.get('head_commit', {}).get('message') == ACTIVATION, 'not one-shot activation')
    head = git('rev-parse', 'HEAD')
    require(os.environ.get('GITHUB_SHA') == head, 'HEAD drift')
    require(subprocess.run(['git', 'merge-base', '--is-ancestor', BASE, head],
                           capture_output=True).returncode == 0, 'QA source base changed')
    changed = git('diff', '--name-only', BASE + '...HEAD').splitlines()
    require(set(changed) == ALLOWED and len(changed) == 4, 'unauthorized path changes')
    return {'branch': BRANCH, 'head': head, 'base': BASE,
            'run_id': os.environ.get('GITHUB_RUN_ID'), 'attempt': 1}

def sources() -> dict:
    evidence = {}
    for path, expected_blob in SOURCE_BLOBS.items():
        data = Path(path).read_bytes()
        require(git_blob(data) == expected_blob and
                git('rev-parse', SOURCE_BASE + ':' + path) == expected_blob,
                'source blob mismatch ' + path)
        evidence[path] = {'blob': expected_blob, 'sha256': digest(data)}
    lock = Path('.github/workflows/canonical-names-lock.yml').read_text()
    require(lock.count('    if: ' + '$' + '{{ false }}') == 42,
            '42 disabled native auto-dispatch gates missing')
    require(lock.count('  verify:\n') == 1, 'names verifier missing')
    canonical = subprocess.check_output(['git', 'show', MAIN + ':README.md'])
    require(git_blob(canonical) == README_BLOB, 'canonical README drift')
    t = Path('tests/issue29_v179_two_month_closed_form_tests.adb').read_text()
    require('with Canonical_Full_Weave_GMP_V164;' in t and
            'with Normative_Oracle;' not in t and
            'with Month_Weaving;' not in t, 'forbidden full-calendar source imported')
    gpr = Path('issue29_v179_two_month_closed_form.gpr').read_text()
    require('with "gnatcoll_gmp.gpr";' in gpr, 'GMP project missing')
    return evidence

def combinatorial_unrank(a: int, b: int, rank: int) -> tuple[int, ...]:
    """First=1, last=2; internal a-1 ones and b-1 twos unrestricted.

    Independent of production H-table recurrence and of the state-DP oracle.
    """
    p, q = a - 1, b - 1
    total = math.comb(p + q, p)
    require(1 <= rank <= total, 'reference rank out of bounds')
    result = [1]
    while p + q:
        first_block = math.comb(p + q - 1, p - 1) if p else 0
        if rank <= first_block:
            result.append(1)
            p -= 1
        else:
            result.append(2)
            q -= 1
            rank -= first_block
    result.append(2)
    require(len(result) == a + b and result.count(1) == a and result.count(2) == b,
            'binomial reference multiplicity mismatch')
    require(rank == 1, 'binomial terminal rank mismatch')
    return tuple(result)

def selected_pair(a: int, b: int) -> bool:
    return a == b or a == 2 or b == 2 or a + b == 125 or (a in BOUNDARIES and b in BOUNDARIES)

def make_reference() -> tuple[bytes, dict]:
    lines = [str(GRID_N)]
    n_pairs = 0
    sample_pairs = 0
    samples = 0
    max_bits = 0
    max_decimal_digits = 0
    max_rank = 0
    for a in range(2, 124):
        for b in range(2, 124):
            count = math.comb(a + b - 2, a - 1)
            max_bits = max(max_bits, count.bit_length())
            max_decimal_digits = max(max_decimal_digits, len(str(count)))
            ranks = sorted({1, (count + 1) // 2, count}) if selected_pair(a, b) else []
            lines.extend((str(a), str(b), str(count), str(len(ranks))))
            prev = ()
            for rank in ranks:
                seq = combinatorial_unrank(a, b, rank)
                if prev:
                    require(prev < seq, 'oracle ranks not strictly lexicographic')
                prev = seq
                lines.append(str(rank))
                lines.extend(map(str, seq))
                samples += 1
                max_rank = max(max_rank, rank)
            sample_pairs += bool(ranks)
            n_pairs += 1
    require(n_pairs == GRID_N and sample_pairs > 300 and samples > 1000,
            'insufficient closed-form pair coverage')
    require(max_bits > 200, 'large GMP ranks not exercised')
    data = ('\n'.join(lines) + '\n').encode('ascii')
    return data, {'pairs': n_pairs, 'sample_pairs': sample_pairs,
                  'sample_ranks': samples, 'maximum_count_bits': max_bits,
                  'maximum_count_decimal_digits': max_decimal_digits,
                  'largest_count': str(math.comb(244, 122)),
                  'greatest_sample_rank': str(max_rank)}

def preflight() -> None:
    env = identity()
    locked = sources()
    fixture, stats = make_reference()
    write_once(REF, fixture)
    receipt = {'schema': SCHEMA, 'status': 'REFERENCE_GENERATED_ZERO_F',
               'identity': env, 'source_blobs': locked,
               'fixture_sha256': digest(fixture), 'fixture_bytes': len(fixture),
               'statistics': stats, 'calendar_calls': 0, 'soak_years': 0,
               'dispatch_halt_remains': True}
    write_json(EV / 'preflight.json', receipt)
    print('V179_CLOSED_FORM_ALL_14884_PAIRS_REFERENCE_READY_ZERO_F')
    print('V179_SAMPLE_RANKS=' + str(stats['sample_ranks']))

def limits() -> None:
    resource.setrlimit(resource.RLIMIT_CPU, (150, 150))
    resource.setrlimit(resource.RLIMIT_AS, (768 * 1024 * 1024, 768 * 1024 * 1024))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))

def stop(p: subprocess.Popen) -> None:
    try:
        os.killpg(p.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass

def run_once() -> None:
    env = identity()
    sources()
    pre = json.loads((EV / 'preflight.json').read_bytes())
    require(pre['identity'] == env and digest(REF.read_bytes()) == pre['fixture_sha256'],
            'independent reference file changed')
    require(BIN.is_file(), 'Ada native GMP test executable missing')
    sym = subprocess.run(['nm', str(BIN)], capture_output=True, check=True)
    require(b'normative_oracle' not in sym.stdout.lower(), 'original F linked')
    require(not (EV / 'RUN_STARTED_ONCE').exists(), 'single native run already used')
    bsha = digest(BIN.read_bytes())
    write_json(EV / 'RUN_STARTED_ONCE', {'head': env['head'],
        'binary_sha256': bsha, 'test_invocations': 1, 'calendar_calls': 0})
    stdout = EV / 'native.stdout'
    stderr = EV / 'native.stderr'
    result = {'schema': SCHEMA, 'identity': env, 'status': 'FAIL_CLOSED',
              'binary_sha256': bsha, 'reference_sha256': pre['fixture_sha256'],
              'calendar_calls': 0, 'soak_years': 0, 'native_invocations': 1}
    started = time.monotonic()
    proc = None
    try:
        with stdout.open('xb') as fo, stderr.open('xb') as fe:
            proc = subprocess.Popen([str(BIN.resolve())], shell=False,
                start_new_session=True, stdin=subprocess.DEVNULL,
                stdout=fo, stderr=fe, preexec_fn=limits)
            violation = None
            while True:
                rc = proc.poll()
                if stdout.stat().st_size + stderr.stat().st_size > 131072:
                    violation = 'OUTPUT_LIMIT'
                    stop(proc)
                    break
                if time.monotonic() - started > 150:
                    violation = 'WALL_TIMEOUT'
                    stop(proc)
                    break
                if rc is not None:
                    break
                time.sleep(0.05)
            proc.wait(timeout=5)
        raw = stdout.read_bytes()
        errs = stderr.read_bytes()
        result.update({'elapsed_seconds': round(time.monotonic() - started, 4),
                       'exit_code': proc.returncode, 'stderr_bytes': len(errs),
                       'violation': violation,
                       'peak_rss_kib': resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss})
        require(proc.returncode == 0 and not errs and violation is None,
                'GMP test nonzero, stderr nonempty or resource cap')
        body = raw.decode('ascii', errors='strict')
        def field(name: str) -> int:
            hits = re.findall('^' + re.escape(name) + r'=\s*([0-9]+)\s*$', body, re.M)
            require(len(hits) == 1, 'missing native verdict field ' + name)
            return int(hits[0])
        actual_pairs = field('V179_CLOSED_FORM_PAIRS')
        actual_samples = field('V179_CLOSED_FORM_SAMPLES')
        assertions = field('V179_CLOSED_FORM_ASSERTIONS')
        expected = pre['statistics']
        require(actual_pairs == expected['pairs'] == GRID_N and
                actual_samples == expected['sample_ranks'] and
                assertions > actual_pairs, 'GMP pair/sample/assertion disagreement')
        result.update({'status': 'PASS_ALL_TWO_MONTH_CLOSED_FORM_GMP_NO_F',
                      'pairs': actual_pairs, 'samples': actual_samples,
                      'assertions': assertions})
    except Exception as exc:
        result['failure'] = str(exc)
        if proc is not None and proc.poll() is None:
            stop(proc)
            proc.wait(timeout=5)
    finally:
        for name, path in (('stdout', stdout), ('stderr', stderr)):
            if path.exists():
                result[name + '_sha256'] = digest(path.read_bytes())
                result[name + '_bytes'] = path.stat().st_size
        write_json(EV / 'result.json', result)
    require(result['status'] == 'PASS_ALL_TWO_MONTH_CLOSED_FORM_GMP_NO_F',
            'v179 failed closed; no automatic rerun')
    print('V179_ALL_14884_BINOMIAL_PAIRS_GMP_PASS_ZERO_F')

if __name__ == '__main__':
    require(len(sys.argv) == 2 and sys.argv[1] in {'self-check', 'preflight', 'run-once'},
            'use self-check|preflight|run-once')
    if sys.argv[1] == 'self-check':
        data, meta = make_reference()
        print(json.dumps({'schema': SCHEMA, 'bytes': len(data),
                          'reference_sha256': digest(data), 'statistics': meta}, indent=2))
    elif sys.argv[1] == 'preflight':
        preflight()
    else:
        run_once()
