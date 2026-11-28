#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31U: original-source Native 256-suffix exhaustive one-byte matrix, 8 shards."""
from __future__ import print_function
import binascii
import json
import os
import sys

import stage1_qa31g_native_eof_probe as native

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
PREFIX = '1 0 0 0'
CAP = 25000
SHARDS = 8
SHARD_SIZE = 32

def need(ok, msg):
    if not ok:
        raise AssertionError(msg)

def main(shard, folder):
    need(0 <= shard < SHARDS, 'invalid shard index')
    need(os.path.isdir(folder), 'missing output folder')
    source = open(native.qa20.SOURCE, 'rb').read()
    need(native.qa20.pin(source) == PIN == native.PIN == native.qa20.PIN,
         'original source Git blob has changed')
    need(native.CAP == 7000, 'upstream observer budget drift')
    native.CAP = CAP
    results = []
    for b in range(shard * SHARD_SIZE, (shard + 1) * SHARD_SIZE):
        label = 'byte_%02x' % b
        raw = PREFIX + chr(b)
        rec = native.run(source, folder, label, raw)
        need(rec['label'] == label
             and rec['raw_hex'] == binascii.hexlify(raw)
             and rec['raw_sha256'] == native.sha(raw)
             and 0 < rec['steps'] <= CAP
             and rec['status'] == 'HALT'
             and rec['error'] is None,
             'case failed original native HALT: ' + label + ' / ' + rec['status'])
        results.append(rec)
        print('QA31U_NATIVE', shard, label, rec['status'], rec['steps'], rec['reads'])
        sys.stdout.flush()
    need(len(results) == SHARD_SIZE, 'missing Native cases')
    doc = {
        'schema': 'qa31u-original-native-one-byte-suffix-v1',
        'source_blob': PIN,
        'source_modified': False,
        'ip_relocated': False,
        'suffix_prefix_hex': binascii.hexlify(PREFIX),
        'shard': shard,
        'shard_size': SHARD_SIZE,
        'total_shards': SHARDS,
        'case_cap_steps': CAP,
        'all_shards_step_cap': CAP * SHARD_SIZE * SHARDS,
        'completed_native_cases': SHARD_SIZE,
        'stage1_pass': False,
        'global_reachability_proven': False,
        'cases': results,
    }
    with open(os.path.join(folder, 'qa31u_receipt.json'), 'wb') as out:
        out.write(json.dumps(doc, sort_keys=True, indent=2) + '\n')
    print('QA31U_NATIVE_SHARD_COMPLETE', shard, SHARD_SIZE)
    print('QA31U_STAGE1_REMAINS_OPEN')

if __name__ == '__main__':
    need(len(sys.argv) == 3, 'usage: qa31u_native_suffix_matrix.py SHARD OUTPUT_DIR')
    main(int(sys.argv[1]), sys.argv[2])
