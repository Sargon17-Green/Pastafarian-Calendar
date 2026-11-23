#!/usr/bin/env python3
"""Fail-closed comparison of Lua5.3 96-prefix output to pre-frozen Python JSON.
PROJECT_ID PC-BRANCH-LUA-HAITIAN. QA only. No production API calls.
"""
import hashlib
import json
import pathlib
import re
import sys

if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(30000)

PROJECT = 'PC-BRANCH-LUA-HAITIAN'
FROZEN = '7bac3d896c332976cde5e97f6527b84084ce95b2'
LUA_COUNT_BLOB = 'df7a6d31714d111a93aced5ccb74a55c09fd78b1'
EXPECTED_TAGS = ('FIRST', 'MIDDLE', 'LAST')


def digest(text):
    return hashlib.sha256(text.encode('ascii')).hexdigest()


def must(condition, message):
    if not condition:
        raise ValueError(message)


def verify(fixture_path, tsv_path, lua_source_path):
    fixture = json.loads(pathlib.Path(fixture_path).read_text(encoding='utf-8'))
    must(fixture['project_id'] == PROJECT, 'project_id mismatch')
    must(fixture['source_sha'] == FROZEN and fixture['source_blob_lua_count'] == LUA_COUNT_BLOB, 'source-lock mismatch')
    must(fixture['total_digits'] == 8654 and fixture['total_sha256'] == 'e3d498d39d6b4dfc401a85b8d9135ff1089a81ace85565ac5dcb123870c09f34', 'count lock mismatch')
    must(len(fixture['entries']) == 3, 'fixture must have exactly three entries')
    src = pathlib.Path(lua_source_path).read_text(encoding='utf-8')
    m = re.search(r'local ACTUAL=\{([\d,]+)\}', src)
    must(m is not None, 'attested Lua vector declaration missing')
    vector = m.group(1)
    months = [int(t) for t in vector.split(',')]
    must(len(months) == 47 and sum(months) == 5294 and all(v >= 2 for v in months), 'attested vector shape mismatch')
    must(digest(vector) == fixture['vector_csv_sha256'], 'Lua vector not source-attested')
    raw = pathlib.Path(tsv_path).read_bytes()
    must(len(raw) < 100_000 and raw.endswith(b'\n'), 'transcript missing terminal LF or over cap')
    must(b'\r' not in raw and b'\x00' not in raw, 'invalid transcript separators')
    try:
        lines = raw.decode('ascii').splitlines()
    except UnicodeDecodeError as exc:
        raise ValueError('non-ASCII transcript') from exc
    must(len(lines) == 3, 'exactly three ordered witnesses required')
    for line, tag, expected in zip(lines, EXPECTED_TAGS, fixture['entries']):
        f = line.split('\t')
        must(len(f) == 4, f'{tag}: invalid TSV field count')
        got_tag, prefix, residual, suffix = f
        must(got_tag == tag == expected['rank'], f'{tag}: witness order/name mismatch')
        must(re.fullmatch(r'(0|[1-9][0-9]*)(,(0|[1-9][0-9]*))*', prefix) is not None, f'{tag}: invalid prefix CSV')
        labels = [int(t) for t in prefix.split(',')]
        must(len(labels) == 96 == expected['prefix_len'] and all(0 <= a < 47 for a in labels), f'{tag}: prefix length or label out of bounds')
        must(prefix == expected['prefix_csv'], f'{tag}: prefix bytes differ from frozen oracle')
        must(digest(prefix) == expected['prefix_sha256'], f'{tag}: prefix SHA mismatch')
        for val, name in ((residual, 'residual'), (suffix, 'suffix')):
            must(re.fullmatch(r'[1-9][0-9]*', val) is not None, f'{tag}: non-canonical {name} decimal')
        must(len(residual) == expected['residual_rank_digits'], f'{tag}: residual length mismatch')
        must(digest(residual) == expected['residual_rank_sha256'], f'{tag}: residual SHA mismatch')
        must(residual[:32] == expected['residual_rank_first32'] and residual[-32:] == expected['residual_rank_last32'], f'{tag}: residual edge mismatch')
        must(len(suffix) == expected['suffix_count_digits'] and digest(suffix) == expected['suffix_count_sha256'], f'{tag}: suffix cardinality mismatch')
        must(int(residual) <= int(suffix), f'{tag}: residual exceeds suffix')
    print('FROZEN_REAL96_LUA53_DIFFERENTIAL=PASS 3/3 SHA256+DECIMAL+96_CSV')
    return lines


def mutation_tests(fixture_path, tsv_path, lua_source_path):
    import tempfile
    lines = pathlib.Path(tsv_path).read_text(encoding='ascii').splitlines()
    cases = []
    for col in (0, 1, 2, 3):
        broken = [line.split('\t') for line in lines]
        if col == 0:
            broken[0][0] = 'UNKNOWN'
        elif col == 1:
            broken[1][1] += ',47'
        elif col == 2:
            broken[1][2] = str(int(broken[1][2]) + 1)
        else:
            broken[2][3] = '0' + broken[2][3]
        cases.append('\n'.join('\t'.join(f) for f in broken) + '\n')
    with tempfile.TemporaryDirectory() as directory:
        for i, case in enumerate(cases, 1):
            file = pathlib.Path(directory) / 'bad.tsv'
            file.write_text(case, encoding='ascii')
            try:
                verify(fixture_path, file, lua_source_path)
            except ValueError:
                pass
            else:
                raise AssertionError(f'mutated transcript {i} accepted')
    print('MUTATION_REJECTS=PASS 4/4')


def main():
    must(len(sys.argv) == 4, 'usage: verifier.py frozen.json real96.tsv real96.lua')
    _, fixture, transcript, source = sys.argv
    verify(fixture, transcript, source)
    mutation_tests(fixture, transcript, source)


if __name__ == '__main__':
    main()
