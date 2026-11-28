#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31S: bounded original Native stdin matrix; no source/IP interventions."""
from __future__ import print_function
import binascii
import json
import os
import sys
import stage1_qa31g_native_eof_probe as native

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CAP = 25000
CASES = [
    ('one_lf', '1\n'),
    ('one_0_lf', '1 0\n'),
    ('one_00_lf', '1 0 0\n'),
    ('one_000_lf', '1 0 0 0\n'),
    ('one_0000_lf', '1 0 0 0 0\n'),
    ('one_tab_0_lf', '1\t0\t0\n'),
    ('one_tab_00_lf', '1\t0\t0\t0\n'),
    ('one_hundred_lf', '100\n'),
    ('one_thousand_lf', '1000\n'),
    ('one_eleven_lf', '111\n'),
    ('one_eleven_eleven_lf', '1111\n'),
    ('one_000_no_lf', '1 0 0 0'),
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
         'QA31S corpus identity')
    native.CAP = CAP
    records = []
    for label, raw in CASES:
        case = native.run(source, folder, label, raw)
        need(case['raw_hex'] == binascii.hexlify(raw) and
             case['label'] == label and 0 < case['steps'] <= CAP,
             'Native input or bound receipt mismatch')
        records.append(case)
        print('QA31S_NATIVE', label, case['status'], case['steps'], case['reads'])
        sys.stdout.flush()
    receipt = {
        'schema': 'qa31s-original-native-frontier-v1',
        'source_blob': PIN,
        'source_modified': False,
        'ip_relocated': False,
        'fresh_native_cases': len(records),
        'cap_per_case': CAP,
        'global_reachability_proven': False,
        'stage1_pass': False,
        'cases': records,
    }
    with open(os.path.join(folder, 'qa31s_receipt.json'), 'wb') as out:
        out.write(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    print('QA31S_12_NATIVE_CASES_RECORDED')
    print('QA31S_NO_STAGE1_PASS')

if __name__ == '__main__':
    need(len(sys.argv) == 2, 'usage: runner output_dir')
    main(sys.argv[1])
