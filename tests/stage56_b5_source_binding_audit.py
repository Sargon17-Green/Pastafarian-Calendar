#!/usr/bin/env python3
"""Stage56 B5: independent Git-byte-binding audit, NOT canonical provenance certification.

The caller MUST supply immutable, independently reviewed source identity and
SHA-256 pins out-of-band. Claims inside EXPORT.json are never trusted as pins.
This gate does not establish that the provider computes canonical years.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

PROJECT_ID = 'PC-BRANCH-PHP-MALAY'
HEX40 = re.compile(r'[0-9a-f]{40}\Z')
HEX64 = re.compile(r'[0-9a-f]{64}\Z')


class AuditError(ValueError):
    pass


def require(ok: bool, code: str) -> None:
    if not ok:
        raise AuditError(code)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_json(data: bytes):
    def pairs(items):
        result = {}
        for key, value in items:
            require(key not in result, 'DUPLICATE_JSON_KEY')
            result[key] = value
        return result

    def constant(_value):
        raise AuditError('NONFINITE_JSON')

    try:
        return json.loads(data.decode('utf-8'), object_pairs_hook=pairs,
                          parse_constant=constant)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise AuditError('INVALID_JSON') from exc


def git(repo: Path, *args: str) -> bytes:
    p = subprocess.run(['git', '-C', str(repo), *args],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       check=False, timeout=15)
    require(p.returncode == 0, 'GIT_OPERATION_FAILED')
    return p.stdout


def safe_path(value: str, provider: bool) -> str:
    require(isinstance(value, str) and value != '' and '\\' not in value and
            not value.startswith('/') and '\x00' not in value, 'UNSAFE_PATH')
    parts = value.split('/')
    require(all(p not in ('', '.', '..') for p in parts), 'UNSAFE_PATH')
    require(parts[0] not in ('tests', 'fixtures', 'oracle') and
            not any(p in ('fixtures', 'oracle') for p in parts), 'TEST_INPUT_AS_SOURCE')
    if provider:
        require(len(parts) > 1 and parts[0] == 'src' and value.endswith('.php'),
                'NOT_PRODUCTION_PROVIDER_PATH')
    return value


def git_file(repo: Path, commit: str, path: str) -> bytes:
    listing = git(repo, 'ls-tree', commit, '--', path).decode('utf-8')
    lines = listing.splitlines()
    require(len(lines) == 1, 'SOURCE_PATH_NOT_TRACKED')
    meta, separator, found_path = lines[0].partition('\t')
    fields = meta.split(' ')
    require(separator == '\t' and found_path == path and len(fields) == 3 and
            fields[0] in ('100644', '100755') and fields[1] == 'blob',
            'SOURCE_NOT_REGULAR_BLOB')
    return git(repo, 'show', f'{commit}:{path}')


def verify(export_bytes: bytes, export_pin: str, repo: Path, commit: str,
           provider_path: str, provider_pin: str, anchor_path: str,
           anchor_pin: str) -> None:
    require(bool(HEX64.fullmatch(export_pin)) and sha256(export_bytes) == export_pin,
            'EXPORT_PIN_MISMATCH')
    require(bool(HEX40.fullmatch(commit)) and
            bool(HEX64.fullmatch(provider_pin)) and
            bool(HEX64.fullmatch(anchor_pin)), 'PIN_FORMAT')
    provider_path = safe_path(provider_path, True)
    anchor_path = safe_path(anchor_path, False)
    require(anchor_path != provider_path, 'SOURCE_PATH_COLLISION')
    actual_head = git(repo, 'rev-parse', '--verify', 'HEAD').decode('ascii').strip()
    require(actual_head == commit, 'HEAD_MISMATCH')

    payload = parse_json(export_bytes)
    require(isinstance(payload, dict) and
            payload.get('project_id') == PROJECT_ID, 'PROJECT_ID_MISMATCH')
    source = payload.get('source')
    require(isinstance(source, dict) and
            source.get('kind') == 'production_export' and
            source.get('source_commit') == commit and
            source.get('provider_path') == provider_path and
            source.get('provider_sha256') == provider_pin and
            source.get('anchor_sha256') == anchor_pin,
            'SOURCE_CLAIM_MISMATCH')

    provider_bytes = git_file(repo, commit, provider_path)
    anchor_bytes = git_file(repo, commit, anchor_path)
    require(sha256(provider_bytes) == provider_pin, 'PROVIDER_BLOB_MISMATCH')
    require(sha256(anchor_bytes) == anchor_pin, 'ANCHOR_BLOB_MISMATCH')

    anchor = parse_json(anchor_bytes)
    require(isinstance(anchor, dict) and set(anchor) == {'number', 'open_gate_day'}
            and type(anchor['number']) is int and anchor['number'] == 5000
            and type(anchor['open_gate_day']) is int, 'ANCHOR_SHAPE')
    require(payload.get('year5000_anchor') == anchor, 'ANCHOR_CLAIM_MISMATCH')
    years = payload.get('years')
    require(isinstance(years, list) and len(years) == 3 and
            all(isinstance(y, dict) and type(y.get('number')) is int and
                y['number'] == 4999 + i for i, y in enumerate(years)),
            'YEARS_IDENTITY')
    require(type(years[1].get('open_gate_day')) is int and
            years[1]['open_gate_day'] == anchor['open_gate_day'],
            'ANCHOR_YEAR_MISMATCH')
    require(git(repo, 'rev-parse', '--verify', 'HEAD').decode('ascii').strip() == commit,
            'HEAD_CHANGED_DURING_AUDIT')


def self_test() -> None:
    def run(*args):
        r = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           check=False, timeout=15)
        if r.returncode:
            raise RuntimeError('SELFTEST_GIT_SETUP_FAILED')
        return r

    with tempfile.TemporaryDirectory(prefix='stage56-b5-audit-') as tmp:
        repo = Path(tmp)
        (repo / 'src').mkdir()
        (repo / 'canonical').mkdir()
        provider_path = 'src/YearStructureProvider.php'
        anchor_path = 'canonical/year5000_anchor.json'
        (repo / provider_path).write_bytes(b'<?php // synthetic self-test only\n')
        anchor_bytes = b'{"number":5000,"open_gate_day":252}\n'
        (repo / anchor_path).write_bytes(anchor_bytes)
        run('git', '-C', tmp, 'init', '-q')
        run('git', '-C', tmp, '-c', 'user.name=QA', '-c', 'user.email=qa@example.invalid',
            'add', 'src', 'canonical')
        run('git', '-C', tmp, '-c', 'user.name=QA', '-c', 'user.email=qa@example.invalid',
            'commit', '-qm', 'synthetic self-test only')
        commit = git(repo, 'rev-parse', 'HEAD').decode('ascii').strip()
        provider_pin = sha256((repo / provider_path).read_bytes())
        anchor_pin = sha256(anchor_bytes)
        input_json = {
            'project_id': PROJECT_ID,
            'source': {'kind': 'production_export', 'provider_path': provider_path,
                       'source_commit': commit, 'provider_sha256': provider_pin,
                       'anchor_sha256': anchor_pin},
            'year5000_anchor': {'number': 5000, 'open_gate_day': 252},
            'years': [{'number': y, 'open_gate_day': (y-4999)*252}
                      for y in (4999, 5000, 5001)],
        }
        encode = lambda obj: json.dumps(obj, separators=(',', ':'), ensure_ascii=False).encode()
        good = encode(input_json)
        def invoke(data=good, export_pin=None, check_commit=commit, prov_path=provider_path,
                   prov_pin=provider_pin, anch_path=anchor_path, anch_pin=anchor_pin):
            verify(data, export_pin if export_pin is not None else sha256(data), repo,
                   check_commit, prov_path, prov_pin, anch_path, anch_pin)

        invoke()
        count = 1
        def reject(expected, **kwargs):
            nonlocal count
            try:
                invoke(**kwargs)
            except AuditError as exc:
                require(str(exc) == expected, f'SELFTEST_WRONG_ERROR_{exc}_EXPECTED_{expected}')
                count += 1
            else:
                raise AssertionError('SELFTEST_MISSING_REJECTION_' + expected)

        reject('EXPORT_PIN_MISMATCH', export_pin='0'*64)
        reject('PIN_FORMAT', check_commit='invalid')
        reject('UNSAFE_PATH', prov_path='../src/YearStructureProvider.php')
        reject('NOT_PRODUCTION_PROVIDER_PATH', prov_path='docs/provider.php')
        reject('SOURCE_PATH_NOT_TRACKED', anch_path='canonical/absent.json')
        reject('HEAD_MISMATCH', check_commit='0'*40)
        reject('SOURCE_CLAIM_MISMATCH', prov_pin='1'*64)
        # Wrong anchor pin must be rejected against source claims before hashing.
        reject('SOURCE_CLAIM_MISMATCH', anch_pin='1'*64)
        mutation = json.loads(good)
        mutation['source']['provider_sha256'] = '1'*64
        reject('PROVIDER_BLOB_MISMATCH', data=encode(mutation), prov_pin='1'*64)
        mutation = json.loads(good)
        mutation['source']['anchor_sha256'] = '1'*64
        reject('ANCHOR_BLOB_MISMATCH', data=encode(mutation), anch_pin='1'*64)
        mutation = json.loads(good)
        mutation['year5000_anchor']['open_gate_day'] = 253
        reject('ANCHOR_CLAIM_MISMATCH', data=encode(mutation))
        mutation = json.loads(good)
        mutation['years'][1]['open_gate_day'] = 253
        reject('ANCHOR_YEAR_MISMATCH', data=encode(mutation))
        mutation = json.loads(good)
        mutation['source']['kind'] = 'fixture'
        reject('SOURCE_CLAIM_MISMATCH', data=encode(mutation))
        dup = good.replace(b'"project_id":', b'"project_id":"DUPLICATE", "project_id":', 1)
        reject('DUPLICATE_JSON_KEY', data=dup)
        require(count == 15, 'SELFTEST_CASE_COUNT')
        print('STAGE56_B5_SOURCE_BINDING_SELF_TEST checks=15 synthetic_only=YES status=PASS')


def main(argv: list[str]) -> int:
    try:
        if len(argv) == 2 and argv[1] == '--self-test':
            self_test()
        elif len(argv) == 9:
            export_path, export_pin, repo, commit, provider_path, provider_pin, anchor_path, anchor_pin = argv[1:]
            verify(Path(export_path).read_bytes(), export_pin, Path(repo), commit,
                   provider_path, provider_pin, anchor_path, anchor_pin)
            print('STAGE56_B5_SOURCE_BINDING source_bytes=PINNED anchor_bytes=PINNED '
                  'actual_year_profiles=0 canonical_review=REQUIRED '
                  'status=BYTE_BINDING_ONLY')
        else:
            print('usage: stage56_b5_source_binding_audit.py --self-test | '
                  'EXPORT.json PINNED_EXPORT_SHA256 REPO_ROOT SOURCE_COMMIT '
                  'PROVIDER_PATH PINNED_PROVIDER_SHA256 ANCHOR_PATH PINNED_ANCHOR_SHA256',
                  file=sys.stderr)
            return 2
    except (AuditError, OSError, RuntimeError, subprocess.TimeoutExpired,
            AssertionError) as exc:
        print('STAGE56_B5_SOURCE_BINDING_REJECT: ' + str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))