#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31T: bounded original Native delimiter/EOF neighborhood; no source/IP edits."""
from __future__ import print_function
import binascii
import json
import os
import sys
import stage1_qa31g_native_eof_probe as native

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CAP = 25000
CASES = [
    ('sep000_no_lf', '1 0 0 0'),
    ('sep001_no_lf', '1 0 0\t0'),
    ('sep010_no_lf', '1 0\t0 0'),
    ('sep011_no_lf', '1 0\t0\t0'),
    ('sep100_no_lf', '1\t0 0 0'),
    ('sep101_no_lf', '1\t0 0\t0'),
    ('sep110_no_lf', '1\t0\t0 0'),
    ('sep111_no_lf', '1\t0\t0\t0'),
    ('space_lf', '1 0 0 0\n'),
    ('space_crlf', '1 0 0 0\r\n'),
    ('space_trailing_space', '1 0 0 0 '),
    ('space_trailing_tab', '1 0 0 0\t'),
]

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def main(folder):
    need(os.path.isdir(folder), 'output folder missing')
    source = open(native.qa20.SOURCE, 'rb').read()
    need(native.qa20.pin(source) == PIN == native.PIN == native.qa20.PIN,
         'original source Git blob changed')
    need(native.CAP == 7000, 'upstream observer budget unexpectedly changed')
    need(len(CASES) == 12 and len(set(label for label, raw in CASES)) == 12,
         'QA31T corpus identity')
    native.CAP = CAP
    records = []
    for label, raw in CASES:
        case = native.run(source, folder, label, raw)
        need(case['raw_hex'] == binascii.hexlify(raw) and
             case['label'] == label and 0 < case['steps'] <= CAP,
             'Native input or bounded receipt mismatch')
        records.append(case)
        print('QA31T_NATIVE', label, case['status'], case['steps'], case['reads'])
        sys.stdout.flush()
    receipt = {
        'schema': 'qa31t-original-native-delimiter-frontier-v1',
        'source_blob': PIN,
        'source_modified': False,
        'ip_relocated': False,
        'fresh_native_cases': len(records),
        'cap_per_case': CAP,
        'total_step_cap': CAP * len(records),
        'global_reachability_proven': False,
        'stage1_pass': False,
        'cases': records,
    }
    with open(os.path.join(folder, 'qa31t_receipt.json'), 'wb') as out:
        out.write(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    print('QA31T_12_NATIVE_CASES_RECORDED')
    print('QA31T_NO_STAGE1_PASS')

if __name__ == '__main__':
    need(len(sys.argv) == 2, 'usage: qa31t_native_matrix output_dir')
    main(sys.argv[1])
