#!/usr/bin/env python3
"""Fail-closed, read-only classifier for FALSE+Arabic Stage2 Native results.

A PASS here is limited to DISCOVERY01 native shape, never full Stage2.
"""
from __future__ import annotations

import hashlib
import json
import sys
import zipfile

PROJECT = 'PC-BRANCH-FALSE-ARABIC'
SHA = 'd05b84ab06a667e2b06d452dc73ca8c7b0837767'
MARKERS = (
    'DISCOVERY01_SHAPE_M0_2M0_3M0_MPLUS1_1',
    'DISCOVERY01_RECREATED_NATIVE_SHAPE_VERIFIED',
)
EVIDENCE_FILES = (
    'evidence.json',
    'native_stdout.txt',
    'combined_sha256.txt',
    'stage02_discovery01_combined.false',
)


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def classify(path: str) -> dict:
    with zipfile.ZipFile(path) as z:
        require(z.testzip() is None, 'ZIP CRC mismatch')
        names = {}
        for member in z.infolist():
            name = member.filename.replace('\\', '/').rsplit('/', 1)[-1]
            if name in EVIDENCE_FILES:
                require(name not in names, 'ambiguous duplicate evidence member: ' + name)
                require(not member.is_dir(), 'evidence member is a directory: ' + name)
                names[name] = member.filename
        require('evidence.json' in names, 'missing evidence.json')
        info = json.loads(z.read(names['evidence.json']).decode('utf-8-sig'))
        require(info.get('project_id') == PROJECT, 'PROJECT_ID mismatch')
        require(info.get('target_sha') == SHA, 'target SHA mismatch')
        exitcode = info.get('runner_exit_code')
        native = info.get('native_exit_code')
        if exitcode == 3 and native is None:
            return {'classification': 'ENVIRONMENT_MISSING', 'native_pass': False,
                    'runner_exit_code': 3}
        if exitcode != 0 or native != 0 or info.get('observed_sha') != SHA:
            return {'classification': 'NATIVE_NOT_ACCEPTED', 'native_pass': False,
                    'runner_exit_code': exitcode}
        require(info.get('git_fetch_exit_code') == 0,
                'Stage2 source fetch success not recorded')
        require(info.get('preflight_exit_code') == 0,
                'UTF-8/extension preflight success not recorded')
        require('native_stdout.txt' in names, 'Native stdout missing')
        stdout = z.read(names['native_stdout.txt']).decode('utf-8-sig')
        require(all(marker in stdout for marker in MARKERS),
                'missing expected Native marker')
        require('combined_sha256.txt' in names, 'missing source SHA evidence')
        require('stage02_discovery01_combined.false' in names,
                'missing combined source bytes for hash verification')
        declared = z.read(names['combined_sha256.txt']).decode('utf-8-sig').split()
        require(bool(declared), 'empty combined source hash evidence')
        source_hash = declared[0].lower()
        require(len(source_hash) == 64 and all(c in '0123456789abcdef' for c in source_hash),
                'invalid combined source hash')
        require(str(info.get('combined_source_sha256') or '').lower() == source_hash,
                'inconsistent combined source hash evidence')
        actual = hashlib.sha256(z.read(names['stage02_discovery01_combined.false'])).hexdigest()
        require(actual == source_hash, 'combined source bytes differ from claimed SHA256')
        runtime_hash = str(info.get('runtime_sha256') or '').lower()
        require(len(runtime_hash) == 64 and all(c in '0123456789abcdef' for c in runtime_hash),
                'runtime SHA256 missing or malformed')
        return {'classification': 'NATIVE_SHAPE_VERIFIED',
                'native_pass': True, 'runner_exit_code': 0,
                'scope': 'DISCOVERY01_ONLY_NOT_STAGE2_ACCEPTANCE'}


if __name__ == '__main__':
    print(json.dumps(classify(sys.argv[1]), ensure_ascii=False, sort_keys=True))
