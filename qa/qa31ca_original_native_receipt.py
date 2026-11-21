#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31CA: original-only, source-pinned PyFunge p-state capture.

No altered execution, no output substitution, no source/IP mutation.
Compares EVERY executed Native STEP against an archived SHA-pinned QA31V
control, and records the actual full TOSS, SO, and physical p write.
Python 2.7 with pinned PyFunge 0.5-rc2.
"""
from __future__ import print_function
import binascii
import gzip
import hashlib
import json
import os
import sys
import stage1_qa20_native_input_route_scan as qa20
import stage1_qa31g_native_eof_probe as observed

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CASE = 'pair_30_30'
RAW = '1 0 0 0' + chr(0x30) + chr(0x30)
WRITER_TICK = 17817
WRITER_IP = [96, 480]
TARGET = [1500, 1860]
MAX_STEPS = 25000

def require(ok, description):
    if not ok:
        raise AssertionError(description)

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def vec(obj):
    return list(map(int, obj))

def native_step(ip, program, t, stream):
    rec = {'t': t, 'ip': vec(ip.position), 'delta': vec(ip.delta),
           'op': int(program.space.get(ip.position)),
           'string': bool(ip.stringmode), 'pre': observed.toss(ip)}
    stream.t = t
    stream.ip = ip
    start = len(stream.events)
    item = {'program': program, 'steps': t - 1}
    qa20.tick_qa20(item)
    require(item['steps'] == t, 'Native tick counter drift')
    rec['post'] = observed.toss(ip)
    rec['next'] = vec(ip.position) if ip in program.ips else None
    rec['next_delta'] = vec(ip.delta) if ip in program.ips else None
    rec['reads'] = stream.events[start:]
    return rec

def signed_input(directory):
    receipt_bytes = open(os.path.join(directory, 'qa31v_receipt.json'), 'rb').read()
    receipt = json.loads(receipt_bytes)
    require(receipt.get('schema') == 'qa31v-original-native-two-byte-v1'
            and receipt.get('source_blob') == SOURCE_BLOB
            and receipt.get('shard') == 0 and receipt.get('shard_size') == 25
            and receipt.get('source_modified') is False
            and receipt.get('ip_relocated') is False
            and receipt.get('stage1_pass') is False, 'signed QA31V provenance')
    records = [c for c in receipt['cases'] if c.get('label') == CASE]
    require(len(records) == 1, 'signed case missing/duplicate')
    rec = records[0]
    trace = 'qa31g_' + CASE + '.jsonl.gz'
    compressed = open(os.path.join(directory, trace), 'rb').read()
    require(rec.get('raw_hex') == binascii.hexlify(RAW)
            and rec.get('raw_sha256') == sha256(RAW)
            and rec.get('status') == 'HALT'
            and rec.get('error') is None
            and rec.get('trace') == trace
            and rec.get('trace_sha256') == sha256(compressed)
            and 0 < rec.get('steps', 0) <= MAX_STEPS,
            'original case raw stdin / compressed trace mismatch')
    return rec, trace, compressed

def run(signed, output):
    require(os.path.isdir(signed) and os.path.isdir(output), 'directories must exist')
    source = open(qa20.SOURCE, 'rb').read()
    require(qa20.pin(source) == SOURCE_BLOB == qa20.PIN == observed.PIN,
            'immutable original source Git blob mismatch')
    control, trace_name, compressed = signed_input(signed)
    stdin = observed.Observed(RAW)
    stdout = observed.StringIO.StringIO()
    platform = qa20.BufferedPlatform([], {}, stdin=stdin, stdout=stdout)
    program = qa20.Program(qa20.Befunge98, platform=platform)
    program.load_code(source)
    program.create_ip()
    require(len(program.ips) == 1, 'original entry IP count')
    expected = gzip.open(os.path.join(signed, trace_name), 'rb')
    replay_name = 'qa31ca_original_replay.jsonl.gz'
    replay_path = os.path.join(output, replay_name)
    replay = gzip.open(replay_path, 'wb')
    witness = None
    ticks = 0
    try:
        while program.ips:
            ticks += 1
            require(ticks <= MAX_STEPS and ticks <= control['steps'],
                    'original run exceeded signed bound')
            require(len(program.ips) == 1, 'original runtime became multi-IP')
            ip = program.ips[0]
            targeted = ticks == WRITER_TICK
            if targeted:
                pre = observed.toss(ip)
                offset = vec(ip.offset)
                pos = vec(ip.position)
                op = int(program.space.get(ip.position))
                require(pos == WRITER_IP and op == ord('p')
                        and not ip.stringmode and not ip.queuemode
                        and not ip.invertmode and len(ip.stack) == 1,
                        'p execution pre-state unsupported')
                require(len(pre) >= 3 and pre[-3] == 62,
                        'original p-value operand changed')
                effective = [pre[-2] + offset[0], pre[-1] + offset[1]]
                require(effective == TARGET,
                        'runtime FungeSpace address is not expected target')
                before = int(program.space.get(tuple(TARGET)))
                witness = {
                    'project_id': PROJECT, 'qa': 'QA31CA', 'case': CASE,
                    'source_git_blob_sha1': SOURCE_BLOB,
                    'tick': ticks, 'ip': pos, 'op': op,
                    'delta': vec(ip.delta),
                    'string_mode': bool(ip.stringmode),
                    'ip_count': len(program.ips),
                    'stack_depth': len(ip.stack),
                    'queue_mode': bool(ip.queuemode),
                    'invert_mode': bool(ip.invertmode),
                    'pre_toss': pre, 'storage_offset': offset,
                    'effective_target': effective, 'cell_before': before,
                    'stdin_hex': binascii.hexlify(RAW),
                    'native_execution_observed': True,
                    'changed_native_run_executed': False,
                    'stage1_accepted': False
                }
            actual = native_step(ip, program, ticks, stdin)
            baseline_line = expected.readline()
            require(baseline_line, 'missing archived physical STEP')
            baseline = json.loads(baseline_line)
            require(actual == baseline,
                    'original full signed STEP mismatch at tick %d' % ticks)
            replay.write(json.dumps(actual, sort_keys=True, separators=(',', ':')) + '\n')
            if targeted:
                require(actual['pre'] == witness['pre_toss']
                        and actual['post'] == witness['pre_toss'][:-3],
                        'p changed unexpected stack cells')
                witness['post_toss'] = actual['post']
                witness['cell_after'] = int(program.space.get(tuple(TARGET)))
                require(witness['cell_after'] == 62 and ticks == WRITER_TICK,
                        'original p physical write receipt mismatch')
        require(expected.readline() == '' and ticks == control['steps'],
                'archived signed trace has trailing/missing physical STEP')
    finally:
        replay.close()
        expected.close()
    require(witness is not None, 'single original p witness not captured')
    require(stdout.getvalue().split() == control['output'],
            'original Native stdout mismatch')
    require(len(stdin.events) == control['reads'],
            'original stdin read-event count mismatch')
    witness['step_count'] = ticks
    witness['raw_sha256'] = sha256(RAW)
    witness['original_signed_trace_sha256'] = control['trace_sha256']
    witness['original_full_step_equality'] = True
    witness['read_events'] = stdin.events
    witness['output'] = stdout.getvalue().split()
    replay_blob = open(replay_path, 'rb').read()
    witness['replay_trace_file'] = replay_name
    witness['replay_trace_sha256'] = sha256(replay_blob)
    path = os.path.join(output, 'qa31ca_original_receipt.json')
    with open(path, 'wb') as f:
        f.write(json.dumps(witness, sort_keys=True, indent=2) + '\n')
    print('QA31CA_ORIGINAL_FULL_SIGNED_STEP_MATCH', ticks)
    print('QA31CA_ORIGINAL_P_RECEIPT', WRITER_TICK,
          'SO', witness['storage_offset'],
          'TOSS', len(witness['pre_toss']),
          'WRITE', witness['cell_before'], witness['cell_after'])
    print('QA31CA_CHANGED_NATIVE_NOT_RUN_STAGE1_OPEN')

if __name__ == '__main__':
    require(len(sys.argv) == 3,
            'usage: qa31ca_original_native_receipt.py SIGNED_DIR OUTPUT_DIR')
    run(sys.argv[1], sys.argv[2])
