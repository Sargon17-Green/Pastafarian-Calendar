#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""One and only one exact-value altered PyFunge execution (QA31CA continuation).

Original source, stdin and entry IP remain immutable. This is an explicitly
intervened run, NOT evidence that a natural input drives the altered route.
Python 2.7 / pinned PyFunge 0.5-rc2. No production implementation changes.
"""
from __future__ import print_function
import binascii
import gzip
import hashlib
import json
import os
import sys
import traceback
import qa31ca_original_native_receipt as control

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
OLD_ZIP_SHA256 = '5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553'
ORIGINAL_TICK = 17817
ORIGINAL_FETCH = 17845
TARGET = [1500, 1860]
IP = [96, 480]
RAW = '1 0 0 0' + chr(48) + chr(48)
MAX_STEPS = 100000


def check(condition, description):
    if not condition:
        raise AssertionError(description)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def original_case(signed):
    zipped = os.path.join(signed, 'original-qa31v-shard0.zip')
    check(sha(open(zipped, 'rb').read()) == OLD_ZIP_SHA256, 'original ZIP SHA-256')
    # Workflow checks ZIP CRC and manifest using the separate Python3 verifier.
    import zipfile
    z = zipfile.ZipFile(zipped)
    check(z.testzip() is None, 'original ZIP CRC')
    receipt = json.loads(z.read('qa31v_receipt.json'))
    check(receipt.get('source_blob') == SOURCE_BLOB and receipt.get('shard') == 0
          and receipt.get('source_modified') is False and
          receipt.get('ip_relocated') is False, 'original signed manifest')
    cases = [r for r in receipt['cases'] if r['label'] == 'pair_30_30']
    check(len(cases) == 1, 'original signed exact input count')
    case = cases[0]
    check(case.get('raw_hex') == binascii.hexlify(RAW) and
          case.get('raw_sha256') == sha(RAW) and
          case.get('status') == 'HALT' and
          case.get('trace') == 'qa31g_pair_30_30.jsonl.gz', 'original signed input')
    packed = z.read(case['trace'])
    check(sha(packed) == case['trace_sha256'], 'original signed trace SHA')
    original = [json.loads(line) for line in gzip.GzipFile(fileobj=__import__('StringIO').StringIO(packed))]
    check(len(original) == case['steps'] and case['steps'] >= ORIGINAL_FETCH,
          'original signed step count')
    return original, case


def read_cell(program, position):
    return int(program.space.get(tuple(position)))


def run(signed, outdir):
    check(os.path.isdir(signed) and os.path.isdir(outdir), 'input/output directories')
    source = open(control.qa20.SOURCE, 'rb').read()
    check(control.qa20.pin(source) == SOURCE_BLOB, 'original production blob drift')
    baseline, original = original_case(signed)
    prior = json.loads(open(os.path.join(signed, 'qa31ca_original_receipt.json'), 'rb').read())
    check(prior.get('original_full_step_equality') is True and
          prior.get('changed_native_run_executed') is False and
          prior.get('step_count') == len(baseline) and
          prior.get('pre_toss') == [62, 1500, 1860] and
          prior.get('storage_offset') == [0, 0] and
          prior.get('cell_before') == 32 and prior.get('cell_after') == 62,
          'QA31CA original native receipt not accepted for this case')
    input_stream = control.observed.Observed(RAW)
    output_stream = control.observed.StringIO.StringIO()
    platform = control.qa20.BufferedPlatform([], {}, stdin=input_stream, stdout=output_stream)
    program = control.qa20.Program(control.qa20.Befunge98, platform=platform)
    program.load_code(source)
    program.create_ip()
    check(len(program.ips) == 1, 'changed original entry IP count')
    changed_path = os.path.join(outdir, 'qa31ca_changed_once.jsonl.gz')
    stream = gzip.open(changed_path, 'wb')
    count = 0
    hits = 0
    fetches = []
    events = []
    output_events = []
    intervention = None
    fatal = None
    status = 'STEP_LIMIT'
    try:
        while program.ips and count < MAX_STEPS:
            count += 1
            check(len(program.ips) == 1, 'unexpected concurrent IP')
            ip = program.ips[0]
            at = control.vec(ip.position)
            op = int(program.space.get(ip.position))
            is_instruction = not bool(ip.stringmode)
            pre_original = control.observed.toss(ip)
            so = control.vec(ip.offset)
            if count < ORIGINAL_TICK:
                check(count <= len(baseline), 'prefix longer than source control')
            if count == ORIGINAL_TICK:
                check(hits == 0 and at == IP and op == ord('p') and is_instruction
                      and len(program.ips) == 1 and len(ip.stack) == 1 and
                      not ip.queuemode and not ip.invertmode and so == [0, 0],
                      'non-original exact p gate')
                check(pre_original == baseline[count-1]['pre'] == prior['pre_toss']
                      and pre_original == [62, 1500, 1860], 'original p TOSS mismatch')
                check([pre_original[-2]+so[0], pre_original[-1]+so[1]] == TARGET,
                      'p physical target mismatch')
                old_cell = read_cell(program, TARGET)
                check(old_cell == prior['cell_before'], 'original physical cell before p')
                # Only mutation in the entire program execution:
                # change the stored-value operand on the actual Native TOSS.
                native_stack = ip.stack[-1]
                native_stack[-3] = 118
                check(control.observed.toss(ip) == [118, 1500, 1860],
                      'intervention modified non-value operand')
                hits += 1
                intervention = {'tick':count,'ip':at,'storage_offset':so,
                                'pre_toss_original':pre_original,
                                'pre_toss_changed':control.observed.toss(ip),
                                'target':TARGET,'cell_before':old_cell,
                                'original_signed_trace_sha256':original['trace_sha256']}
            if count > ORIGINAL_TICK and at == IP and op == ord('p') and is_instruction:
                # Explicit no-second-fire guard, even when execution loops.
                check(False, 'exact writer instruction executed more than once')
            native_pre = control.observed.toss(ip)
            pg = None
            if is_instruction and op in (ord('p'), ord('g')):
                n = 3 if op == ord('p') else 2
                check(len(native_pre) >= n, 'cannot attest underflowed p/g operand')
                xy = [native_pre[-2] + so[0], native_pre[-1] + so[1]]
                pg = {'tick':count,'op':op,'ip':at,'storage_offset':so,
                      'target':xy,'pre_toss':native_pre,
                      'cell_before':read_cell(program, xy)}
            stdout_before = output_stream.getvalue()
            row = control.native_step(ip, program, count, input_stream)
            stdout_after = output_stream.getvalue()
            check(stdout_after.startswith(stdout_before), 'stdout rewound unexpectedly')
            if len(stdout_after) != len(stdout_before):
                output_events.append({'tick':count,'append':stdout_after[len(stdout_before):]})
            stream.write(json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n')
            if count < ORIGINAL_TICK:
                check(row == baseline[count-1], 'unmodified prefix drift at tick '+str(count))
            if count == ORIGINAL_TICK:
                expected = baseline[count-1]
                for key in ('t','ip','delta','op','string','post','next','next_delta','reads'):
                    check(row.get(key) == expected.get(key), 'writer control drift '+key)
                check(row['pre'] == [118,1500,1860] and row['post'] == [],
                      'native p stack mutation/pop mismatch')
                intervention['cell_after'] = read_cell(program, TARGET)
                check(intervention['cell_after'] == 118, 'actual Native p did not write 118')
            if pg is not None:
                pg['post_toss'] = row['post']
                pg['cell_after'] = read_cell(program, pg['target'])
                events.append(pg)
            if at == TARGET and not row['string']:
                fetches.append({'tick':count,'op':row['op'],'ip':at,
                                'next':row['next'],'next_delta':row['next_delta'],
                                'cell_observed':read_cell(program, TARGET)})
                if count == ORIGINAL_FETCH:
                    check(row['op'] == ord('v') and row['next'] == [1500, 1861]
                          and row['next_delta'] == [0,1],
                          'expected altered Native v fetch not physically observed')
        if not program.ips:
            status = 'HALT'
        check(hits == 1 and intervention is not None,
              'exactly one changed Native p interception required')
        check(len(fetches) >= 1 and fetches[0]['tick'] == ORIGINAL_FETCH,
              'changed Native target fetch absent or delayed')
    except Exception as exc:
        fatal = type(exc).__name__ + ': ' + str(exc)
        status = 'RUNTIME_OR_ATTESTATION_ERROR'
        traceback.print_exc()
    finally:
        stream.close()
        packed = open(changed_path, 'rb').read()
        receipt = {'project_id':PROJECT,'qa':'QA31CA_CHANGED_ONCE',
                   'kind':'INTERVENED_NATIVE_NOT_NATURAL_INPUT',
                   'original_source_modified':False,'original_entry_ip_relocated':False,
                   'source_git_blob_sha1':SOURCE_BLOB, 'stdin_hex':binascii.hexlify(RAW),
                   'stdin_sha256':sha(RAW), 'old_signed_zip_sha256':OLD_ZIP_SHA256,
                   'old_signed_trace_sha256':original['trace_sha256'],
                   'changed_native_run_executed':count > 0,
                   'single_interception_hits':hits,'writer':intervention,
                   'fetches_at_target':fetches,'pg_events':events,
                   'trace':'qa31ca_changed_once.jsonl.gz',
                   'trace_sha256':sha(packed),'steps':count,
                   'read_events':input_stream.events,
                   'stdout_events':output_events,
                   'stdout_tokens':output_stream.getvalue().split(),
                   'status':status,'error':fatal,'cap':MAX_STEPS,
                   'stage1_accepted':False,'differential_accepted':False}
        with open(os.path.join(outdir,'qa31ca_changed_receipt.json'),'wb') as f:
            f.write(json.dumps(receipt,sort_keys=True,indent=2)+'\n')
        print('QA31CA_CHANGED_NATIVE_RUN',status,'STEPS',count,'HITS',hits,
              'TARGET_FETCHES',len(fetches),'STAGE1_OPEN')
    check(fatal is None, 'changed Native failed: '+str(fatal))
    check(status == 'HALT', 'changed Native did not halt under finite budget')


if __name__ == '__main__':
    check(len(sys.argv) == 3,
          'usage: qa31ca_changed_native_once.py QA31CA_CONTROL_DIR OUTPUT_DIR')
    run(sys.argv[1], sys.argv[2])
