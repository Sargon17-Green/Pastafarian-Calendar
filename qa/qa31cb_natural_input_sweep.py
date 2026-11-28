#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31CB: 900 unmodified PyFunge Native runs for three-digit stdin tokens."""
from __future__ import print_function
import binascii
import gzip
import hashlib
import json
import os
import shutil
import sys
import StringIO
import stage1_qa20_native_input_route_scan as qa20
import stage1_qa31g_native_eof_probe as observed

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CAP = 50000
OWNER = [19, 1696]
CODE = [1500, 1860]
BOUNDARY = set([100, 199, 500, 999])
STATUS = set(['HALT', 'STEP_LIMIT', 'MULTI_IP', 'RUNTIME_ERROR'])


def need(ok, message):
    if not ok:
        raise AssertionError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def vec(value):
    return list(map(int, value))


def target_events_match(metadata):
    cells = metadata.get('cells', {})
    owner = cells.get('input_owner', {})
    code = cells.get('dynamic_code_cell', {})
    need(metadata.get('schema') == 'qa31cb-source-cell-metadata-v1'
         and metadata.get('project_id') == PROJECT
         and metadata.get('source_git_blob_sha1') == PIN
         and owner.get('coordinate') == OWNER
         and code.get('coordinate') == CODE,
         'source-cell metadata identity/coordinates')


def run_case(source, token, traces_dir, output_dir):
    raw = '1 0 0 %03d' % token
    label = 'token_%03d' % token
    stdin = observed.Observed(raw)
    stdout = StringIO.StringIO()
    platform = qa20.BufferedPlatform([], {}, stdin=stdin, stdout=stdout)
    program = qa20.Program(qa20.Befunge98, platform=platform)
    program.load_code(source)
    program.create_ip()
    need(len(program.ips) == 1, 'fresh Native program must start with one IP')

    trace_name = label + '.jsonl.gz'
    trace_path = os.path.join(traces_dir, trace_name)
    packed = gzip.open(trace_path, 'wb')
    item = {'program': program, 'steps': 0}
    ticks = 0
    status = 'HALT'
    error = None
    owner_events = []
    code_events = []
    fetches = []

    try:
        while program.ips:
            if len(program.ips) != 1:
                status = 'MULTI_IP'
                error = 'more than one active instruction pointer'
                break
            if ticks >= CAP:
                status = 'STEP_LIMIT'
                break

            ticks += 1
            ip = program.ips[0]
            position = vec(ip.position)
            delta = vec(ip.delta)
            storage_offset = vec(ip.offset)
            opcode = int(program.space.get(ip.position))
            string_mode = bool(ip.stringmode)
            pre = observed.toss(ip)

            pg = None
            if not string_mode and opcode in (ord('p'), ord('g')):
                arity = 3 if opcode == ord('p') else 2
                pg = {
                    'tick': ticks, 'op': opcode, 'ip': position,
                    'storage_offset': storage_offset, 'pre_toss': pre,
                    'target': None, 'cell_before': None, 'cell_after': None,
                    'result': None
                }
                if len(pre) >= arity:
                    target = [pre[-2] + storage_offset[0],
                              pre[-1] + storage_offset[1]]
                    pg['target'] = target
                    pg['cell_before'] = int(program.space.get(tuple(target)))

            fetch = None
            if not string_mode and position == CODE:
                fetch = {'tick': ticks, 'ip': position, 'op': opcode,
                         'cell_observed': int(program.space.get(tuple(CODE)))}

            stdin.t = ticks
            stdin.ip = ip
            read_start = len(stdin.events)
            stdout_before = stdout.getvalue()
            step_error = None
            try:
                qa20.tick_qa20(item)
                need(item['steps'] == ticks, 'Native tick counter drift')
            except Exception as exc:
                step_error = type(exc).__name__ + ': ' + str(exc)
                status = 'RUNTIME_ERROR'
                error = step_error

            post = observed.toss(ip)
            row = {
                't': ticks, 'ip': position, 'delta': delta, 'op': opcode,
                'string': string_mode, 'pre': pre, 'post': post,
                'storage_offset': storage_offset, 'pg': pg, 'fetch': fetch,
                'next': vec(ip.position) if ip in program.ips else None,
                'next_delta': vec(ip.delta) if ip in program.ips else None,
                'reads': stdin.events[read_start:]
            }

            stdout_after = stdout.getvalue()
            if stdout_after.startswith(stdout_before):
                stdout_delta = stdout_after[len(stdout_before):]
            else:
                stdout_delta = ''
                status = 'RUNTIME_ERROR'
                error = 'stdout buffer unexpectedly rewound'
            row['stdout_delta_hex'] = binascii.hexlify(stdout_delta)

            if pg is not None and pg['target'] is not None:
                pg['cell_after'] = int(program.space.get(tuple(pg['target'])))
                if opcode == ord('g') and post:
                    pg['result'] = post[-1]
                if pg['target'] == OWNER:
                    owner_events.append(pg)
                if pg['target'] == CODE:
                    code_events.append(pg)
            if fetch is not None:
                fetches.append(fetch)
            if step_error is not None:
                row['error'] = step_error

            packed.write(json.dumps(row, sort_keys=True,
                                    separators=(',', ':')) + '\n')
            if status == 'RUNTIME_ERROR':
                break
            if len(program.ips) > 1:
                status = 'MULTI_IP'
                error = 'more than one active instruction pointer after Native step'
                break
    finally:
        packed.close()

    if status not in STATUS:
        status = 'RUNTIME_ERROR'
        error = 'unrecognized Native termination state'

    trace_bytes = open(trace_path, 'rb').read()
    stdout_bytes = stdout.getvalue()
    receipt = {
        'schema': 'qa31cb-natural-input-case-v1',
        'project_id': PROJECT,
        'qa': 'QA31CB',
        'label': label,
        'input_token': token,
        'raw_hex': binascii.hexlify(raw),
        'raw_sha256': sha(raw),
        'source_git_blob_sha1': PIN,
        'source_modified': False,
        'ip_relocated': False,
        'native_execution_observed': True,
        'trace_file': trace_name,
        'trace_sha256': sha(trace_bytes),
        'steps': ticks,
        'status': status,
        'error': error,
        'read_events': stdin.events,
        'stdout_hex': binascii.hexlify(stdout_bytes),
        'owner_pg_events': owner_events,
        'code_pg_events': code_events,
        'target_fetches': fetches,
        'global_reachability_proven': False,
        'stage1_accepted': False
    }

    if token in BOUNDARY or status != 'HALT':
        shutil.copyfile(trace_path, os.path.join(output_dir, trace_name))
    return receipt


def main(traces_dir, output_dir):
    need(os.path.isdir(traces_dir), 'missing temporary trace directory')
    if not os.path.isdir(output_dir):
        os.makedirs(output_dir)

    source = open(qa20.SOURCE, 'rb').read()
    need(qa20.pin(source) == PIN == qa20.PIN,
         'immutable production source Git blob mismatch')
    metadata_path = os.path.join('qa', 'qa31cb_source_cells.json')
    metadata = json.loads(open(metadata_path, 'rb').read())
    target_events_match(metadata)
    shutil.copyfile(metadata_path,
                    os.path.join(output_dir, 'qa31cb_source_cells.json'))

    cases_path = os.path.join(output_dir, 'qa31cb_cases.jsonl')
    counts = {'HALT': 0, 'STEP_LIMIT': 0, 'MULTI_IP': 0, 'RUNTIME_ERROR': 0}
    total_steps = 0
    with open(cases_path, 'wb') as cases_file:
        for token in range(100, 1000):
            receipt = run_case(source, token, traces_dir, output_dir)
            need(receipt['input_token'] == token and
                 receipt['label'] == 'token_%03d' % token,
                 'case order/identity drift')
            cases_file.write(json.dumps(receipt, sort_keys=True,
                                        separators=(',', ':')) + '\n')
            counts[receipt['status']] += 1
            total_steps += receipt['steps']
            print('QA31CB_NATIVE_CASE', token, receipt['status'],
                  receipt['steps'], 'reads', len(receipt['read_events']),
                  'owner_pg', len(receipt['owner_pg_events']),
                  'code_pg', len(receipt['code_pg_events']),
                  'fetches', len(receipt['target_fetches']))
            sys.stdout.flush()

    summary = {
        'schema': 'qa31cb-native-sweep-summary-v1',
        'project_id': PROJECT,
        'qa': 'QA31CB',
        'source_git_blob_sha1': PIN,
        'first_token': 100,
        'last_token': 999,
        'expected_cases': 900,
        'completed_receipts': 900,
        'status_counts': counts,
        'physical_step_records': total_steps,
        'boundary_traces': sorted(BOUNDARY),
        'runtime_cap_per_case': CAP,
        'global_reachability_proven': False,
        'stage1_accepted': False
    }
    with open(os.path.join(output_dir, 'qa31cb_native_summary.json'), 'wb') as f:
        f.write(json.dumps(summary, sort_keys=True, indent=2) + '\n')
    print('QA31CB_NATIVE_SWEEP_RECEIPTS_WRITTEN', 900)
    print('QA31CB_STAGE1_REMAINS_OPEN')


if __name__ == '__main__':
    need(len(sys.argv) == 3,
         'usage: qa31cb_natural_input_sweep.py TRACE_DIR OUTPUT_DIR')
    main(sys.argv[1], sys.argv[2])
