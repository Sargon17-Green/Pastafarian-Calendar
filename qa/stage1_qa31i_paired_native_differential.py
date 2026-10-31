#!/usr/bin/env python3
"""QA31I: bounded, original signed Native pair; no new Native and no source edits."""
import argparse
import gzip
import hashlib
import io
import json
import zipfile
from pathlib import Path

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
ZIP_SHA256 = 'e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161'
TRACE_SHA256 = {
    'digit': '018091d998f546a918575f3f3f93e07cad68bd88d5adcdf8a36663cfafdcc4aa',
    'digit_space': '69f868bd3969b77e7640cb355c6429e73822c6845e8968d82ef2b45ecbf04ad7',
}
EXPECTED = {'digit': (b'1', 2046), 'digit_space': (b'1 ', 3038)}
STATE_KEYS = ('ip', 'delta', 'op', 'string', 'pre', 'post', 'next', 'next_delta')


def need(value, message):
    if not value:
        raise AssertionError(message)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def signed_pair(zip_path):
    raw = Path(zip_path).read_bytes()
    need(digest(raw) == ZIP_SHA256, 'historical original ZIP SHA256 mismatch')
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        need(z.testzip() is None, 'ZIP CRC failure')
        receipt = json.loads(z.read('qa31g_receipt.json'))
        need(receipt['schema'] == 'qa31g-original-native-eof-v1'
             and receipt['source_blob'] == SOURCE_BLOB
             and receipt['source_modified'] is False
             and receipt['ip_relocated'] is False
             and receipt['stage1_pass'] is False, 'native provenance')
        cases = {c['label']: c for c in receipt['cases']}
        need(len(cases) == 3 and set(cases) == {'empty', 'digit', 'digit_space'}, 'original trio')
        traces = {}
        for label, (stdin, count) in EXPECTED.items():
            c = cases[label]
            name = 'qa31g_' + label + '.jsonl.gz'
            need(c['raw_hex'] == stdin.hex() and c['raw_sha256'] == digest(stdin), 'stdin bytes')
            need(c['status'] == 'HALT' and c['error'] is None and c['steps'] == count
                 and c['trace'] == name and c['trace_sha256'] == TRACE_SHA256[label], 'receipt')
            need(c['output'] == ['-1'] * 7, 'output comparison (finite only)')
            compressed = z.read(name)
            need(digest(compressed) == TRACE_SHA256[label], 'compressed trace hash')
            traces[label] = [json.loads(line) for line in gzip.decompress(compressed).splitlines()]
            need(len(traces[label]) == count, 'physical STEP count')
    return traces


def pair_assert(a, b):
    """Checks physical state equality, earliest state divergence, and separate gates."""
    need(len(a) == 2046 and len(b) == 3038, 'bounded signed pair lengths')
    for i in range(1131):
        need(a[i]['t'] == b[i]['t'] == i + 1, 'common-prefix tick ordering')
        need(all(a[i][k] == b[i][k] for k in STATE_KEYS), 'earlier physical-state discrepancy')
        if i != 291:
            need(a[i]['reads'] == b[i]['reads'], 'unexpected earlier input transcript divergence')
    x, y = a[291], b[291]
    need(x['ip'] == y['ip'] == [13, 5] and x['op'] == y['op'] == 126
         and x['pre'] == y['pre'] == [] and x['post'] == y['post'] == [49],
         'first native read must produce the same immediate physical state')
    need(len(x['reads']) == len(y['reads']) == 1, 'first native input-read count')
    read_digit, read_space = x['reads'][0], y['reads'][0]
    need(read_digit == {'t': 292, 'method': 'readline', 'start': 0, 'end': 1,
                        'hex': '31', 'ip': [13, 5], 'stack': []}, 'digit read event')
    need(read_space == {'t': 292, 'method': 'readline', 'start': 0, 'end': 2,
                        'hex': '3120', 'ip': [13, 5], 'stack': []}, 'trailing-space read event')
    x, y = a[1131], b[1131]
    need(x['t'] == y['t'] == 1132 and x['ip'] == y['ip'] == [13, 5]
         and x['op'] == y['op'] == 126 and x['pre'] == y['pre'] == [],
         'first differing physical step')
    need(x['reads'] == [{'t': 1132, 'method': 'readline', 'start': 1,
                          'end': 1, 'hex': '', 'ip': [13, 5], 'stack': []}]
         and x['post'] == [] and x['next'] == [12, 5]
         and x['next_delta'] == [-1, 0], 'EOF must reflect the digit-only native IP')
    need(y['reads'] == [] and y['post'] == [32] and y['next'] == [14, 5]
         and y['next_delta'] == [1, 0], 'buffered space must advance native IP')
    def find_gate(trace, tick, expected):
        s = trace[tick - 1]
        need(s['ip'] == [89, 29] and s['op'] == ord('j')
             and s['pre'][-1] == expected, 'original row29 j gate')
    find_gate(a, 1254, 61)
    find_gate(b, 2676, 0)
    need(a[-1]['next'] is None and b[-1]['next'] is None, 'finite native HALT')
    return {'input_first_difference_tick': 292,
            'physical_state_first_difference_tick': 1132,
            'common_physical_state_steps': 1131,
            'digit_eof_reflection': [12, 5],
            'digit_space_buffered_advance': [14, 5],
            'row29_gate': {'digit': {'tick': 1254, 'operand': 61},
                           'digit_space': {'tick': 2676, 'operand': 0}}}


def run(source, zip_path):
    pair = signed_pair(zip_path)
    if source is not None:
        import stage1_qa31h_last_writer_reader_audit as h
        rows = h.source_rows(source)
        need(h.SOURCE_BLOB == SOURCE_BLOB and h.ZIP_SHA == ZIP_SHA256,
             'independent source/evidence pin drift')
        for label, trace in pair.items():
            h.trace_audit(label, trace, rows)
    facts = pair_assert(pair['digit'], pair['digit_space'])
    return pair, {'schema': 'qa31i-signed-native-pair-v1',
                  'source_blob': SOURCE_BLOB, 'signed_native_zip_sha256': ZIP_SHA256,
                  'source_verified': source is not None,
                  'original_native_cases': 2, 'original_physical_steps': 5084,
                  'new_native_executions': 0, 'stage1_pass': False,
                  'global_ownership_proven': False,
                  'facts': facts}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('source')
    p.add_argument('original_native_zip')
    p.add_argument('--output', default='qa31i_pair.json')
    args = p.parse_args()
    _, report = run(args.source, args.original_native_zip)
    Path(args.output).write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    need(report['source_verified'], 'source full-trace verification required for CI')
    print('QA31I_SIGNED_ORIGINAL_NATIVE_CASES 2')
    print('QA31I_SIGNED_PHYSICAL_STEPS 5084')
    print('QA31I_COMMON_PHYSICAL_STEPS 1131')
    print('QA31I_FIRST_STATE_DIVERGENCE 1132')
    print('QA31I_NO_NEW_NATIVE_NO_STAGE1_PASS')


if __name__ == '__main__':
    main()
