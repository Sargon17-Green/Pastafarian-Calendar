#!/usr/bin/env python3
"""Independent, fail-closed differential verifier of QA31CA one-shot Native.

Does NOT import Native producer or its fixture/preflight logic. Reads the
immutable signed QA31V control and two complete physical Native STEP streams.
PASS is strictly for this intervened one-case experiment, never Stage1.
"""
from __future__ import annotations
import argparse
import copy
import gzip
import hashlib
import io
import json
import zipfile
from pathlib import Path

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
QA31V_SHA = '5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553'
QA31CA_ARTIFACT_SHA = '988045a5a51fde51cfa544ca3fdbba23b7b33fa76f7e9e89b9a942c0ab3d707c'
INPUT = bytes.fromhex('312030203020303030')
WRITER = 17817
FETCH = 17845
ADDRESS = [1500, 1860]
WRITER_IP = [96, 480]
MAX_STEPS = 100000


def need(condition, reason):
    if not condition:
        raise AssertionError(reason)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def gitblob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode('ascii') + b'\0' + data).hexdigest()


def trace(blob):
    return [json.loads(line) for line in gzip.decompress(blob).splitlines()]


def read_controls(original_artifact, source):
    outer = original_artifact.read_bytes()
    need(sha(outer) == QA31CA_ARTIFACT_SHA, 'QA31CA control artifact SHA256')
    need(gitblob(source.read_bytes()) == SOURCE_BLOB, 'source immutable Git blob')
    with zipfile.ZipFile(io.BytesIO(outer)) as z:
        need(z.testzip() is None, 'QA31CA outer artifact CRC')
        archive = z.read('original-qa31v-shard0.zip')
        need(sha(archive) == QA31V_SHA, 'immutable original QA31V ZIP digest')
        prior = json.loads(z.read('qa31ca_original_receipt.json'))
        prior_replay = z.read('qa31ca_original_replay.jsonl.gz')
        old_audit = json.loads(z.read('audit.json'))
        need(prior['replay_trace_sha256'] == sha(prior_replay) and
             old_audit['new_native_original_replay'] == 'FULL_SIGNED_MATCH_PASS' and
             old_audit['independent_detached_hostiles_rejected'] >= 12 and
             old_audit['stage1_accepted'] is False, 'QA31CA original acceptance evidence')
    with zipfile.ZipFile(io.BytesIO(archive)) as z:
        need(z.testzip() is None, 'original QA31V ZIP CRC')
        manifest = json.loads(z.read('qa31v_receipt.json'))
        need(manifest.get('source_blob') == SOURCE_BLOB and
             manifest.get('source_modified') is False and
             manifest.get('ip_relocated') is False and
             manifest.get('shard') == 0, 'original signed source provenance')
        cases = [c for c in manifest['cases'] if c['label'] == 'pair_30_30']
        need(len(cases) == 1, 'original exact single case')
        c = cases[0]
        need(c['raw_hex'] == INPUT.hex() and c['raw_sha256'] == sha(INPUT) and
             c['status'] == 'HALT' and c['trace'] == 'qa31g_pair_30_30.jsonl.gz',
             'original immutable input and case identity')
        oldblob = z.read(c['trace'])
        need(sha(oldblob) == c['trace_sha256'], 'old signed compressed STEP SHA256')
        signed = trace(oldblob)
    baseline = trace(prior_replay)
    need(len(signed) == len(baseline) == c['steps'] == 17875, 'original signed STEP count')
    for i, (a, b) in enumerate(zip(signed, baseline), 1):
        need(a == b, 'QA31CA original replay differs from signed at step '+str(i))
    need(prior.get('source_git_blob_sha1') == SOURCE_BLOB and
         prior.get('case') == 'pair_30_30' and
         prior.get('tick') == WRITER and prior.get('ip') == WRITER_IP and
         prior.get('storage_offset') == [0, 0] and
         prior.get('pre_toss') == [62, 1500, 1860] and
         prior.get('post_toss') == [] and
         prior.get('cell_before') == 32 and prior.get('cell_after') == 62 and
         prior.get('read_events') == [r for step in signed for r in step['reads']] and
         prior.get('output') == c['output'] and
         prior.get('step_count') == c['steps'], 'original physical p/stdin/stdout witness')
    return c, signed, prior


def verify(receipt, rows, signed, old_receipt):
    need(type(receipt) is dict and type(rows) is list, 'changed evidence shape')
    need(receipt.get('project_id') == PROJECT and
         receipt.get('qa') == 'QA31CA_CHANGED_ONCE' and
         receipt.get('kind') == 'INTERVENED_NATIVE_NOT_NATURAL_INPUT' and
         receipt.get('original_source_modified') is False and
         receipt.get('original_entry_ip_relocated') is False and
         receipt.get('source_git_blob_sha1') == SOURCE_BLOB and
         receipt.get('old_signed_zip_sha256') == QA31V_SHA and
         receipt.get('old_signed_trace_sha256') == old_receipt['original_signed_trace_sha256'] and
         receipt.get('stdin_hex') == INPUT.hex() and
         receipt.get('stdin_sha256') == sha(INPUT) and
         receipt.get('changed_native_run_executed') is True and
         receipt.get('single_interception_hits') == 1 and
         receipt.get('stage1_accepted') is False and
         receipt.get('differential_accepted') is False and
         receipt.get('status') == 'HALT' and
         receipt.get('error') is None and
         receipt.get('cap') == MAX_STEPS and
         receipt.get('steps') == len(rows) and
         WRITER < len(rows) <= MAX_STEPS, 'changed provenance / halt / bounded scope')
    for i, r in enumerate(rows, 1):
        need(type(r) is dict and type(r.get('t')) is int and r['t'] == i and
             type(r.get('ip')) is list and len(r['ip']) == 2 and
             all(type(v) is int for v in r['ip']) and
             type(r.get('delta')) is list and len(r['delta']) == 2 and
             all(type(v) is int for v in r['delta']) and
             type(r.get('op')) is int and
             type(r.get('string')) is bool and
             type(r.get('pre')) is list and
             type(r.get('post')) is list and
             type(r.get('reads')) is list and
             all(type(v) is int for v in r['pre']+r['post']),
             'changed STEP schema/order at '+str(i))
        if i < len(rows):
            need(r.get('next') == rows[i]['ip'] and
                 r.get('next_delta') == rows[i]['delta'],
                 'changed physical IP continuity at '+str(i))
        if i < WRITER:
            need(r == signed[i-1], 'altered run diverged before p at '+str(i))
    first = rows[WRITER-1]
    old = signed[WRITER-1]
    need(old['ip'] == WRITER_IP and old['op'] == 112 and
         old['pre'] == [62,1500,1860] and old['post'] == [] and
         first['pre'] == [118,1500,1860] and first['post'] == [],
         'exact one-value p intervention at tick 17817')
    for k in ('t','ip','delta','op','string','post','next','next_delta','reads'):
        need(first.get(k) == old.get(k), 'writer p changed protected field '+k)
    need(rows[FETCH-1]['ip'] == ADDRESS and rows[FETCH-1]['op'] == 118 and
         rows[FETCH-1]['next'] == [1500,1861] and
         rows[FETCH-1]['next_delta'] == [0,1] and
         signed[FETCH-1]['op'] == 62,
         'real altered dynamic opcode v and southern first step')
    w = receipt.get('writer')
    need(type(w) is dict and w.get('tick') == WRITER and w.get('ip') == WRITER_IP and
         w.get('storage_offset') == [0,0] and w.get('target') == ADDRESS and
         w.get('pre_toss_original') == [62,1500,1860] and
         w.get('pre_toss_changed') == [118,1500,1860] and
         w.get('cell_before') == 32 and w.get('cell_after') == 118 and
         w.get('original_signed_trace_sha256') == old_receipt['original_signed_trace_sha256'],
         'writer actual physical FungeSpace receipt')
    got_fetches = [r for r in rows if r['ip'] == ADDRESS and not r['string']]
    f = receipt.get('fetches_at_target')
    need(type(f) is list and len(f) == len(got_fetches) and len(f) >= 1 and
         f[0].get('tick') == FETCH and f[0].get('op') == 118 and
         f[0].get('cell_observed') == 118, 'changed target fetch receipts')
    for a,b in zip(f,got_fetches):
        need(a.get('tick') == b['t'] and a.get('op') == b['op'] and
             a.get('ip') == b['ip'] and a.get('next') == b['next'] and
             a.get('next_delta') == b['next_delta'], 'changed target fetch mismatch')
    pgs = [r for r in rows if not r['string'] and r['op'] in (112,103)]
    events = receipt.get('pg_events')
    need(type(events) is list and len(events) == len(pgs), 'missing Native p/g physical events')
    for e,r in zip(events,pgs):
        so = e.get('storage_offset')
        need(type(so) is list and len(so) == 2 and
             all(type(v) is int for v in so), 'p/g SO shape')
        pre = r['pre']
        need(len(pre) >= (3 if r['op'] == 112 else 2), 'p/g operand underflow unverified')
        expected_target = [pre[-2]+so[0], pre[-1]+so[1]]
        need(e.get('tick') == r['t'] and e.get('op') == r['op'] and
             e.get('ip') == r['ip'] and e.get('pre_toss') == pre and
             e.get('post_toss') == r['post'] and
             e.get('target') == expected_target and
             type(e.get('cell_before')) is int and type(e.get('cell_after')) is int,
             'Native p/g event mismatch')
        if r['op'] == 112:
            need(e['cell_after'] == pre[-3], 'p physically stored wrong value')
    changed_p = [e for e in events if e['tick'] == WRITER]
    need(len(changed_p) == 1 and changed_p[0]['cell_before'] == 32 and
         changed_p[0]['cell_after'] == 118 and
         changed_p[0]['target'] == ADDRESS, 'writer event owner parity')
    evidence_reads = [x for r in rows for x in r['reads']]
    need(receipt.get('read_events') == evidence_reads, 'changed stdin event reconciliation')
    out_events = receipt.get('stdout_events')
    need(type(out_events) is list and
         all(type(e) is dict and type(e.get('tick')) is int and
             type(e.get('append')) is str and e['append'] != '' for e in out_events),
         'changed stdout append event shape')
    need([e['tick'] for e in out_events] == sorted(e['tick'] for e in out_events) and
         all(1 <= e['tick'] <= len(rows) for e in out_events) and
         ''.join(e['append'] for e in out_events).split() == receipt.get('stdout_tokens'),
         'changed stdout event reconciliation')
    return {'project_id':PROJECT, 'qa':'QA31CA_CHANGED_ONCE',
            'original_complete_steps_verified':len(signed),
            'changed_native_steps_verified':len(rows),
            'first_changed_step':WRITER,
            'physical_changed_opcode_at_tick':FETCH,
            'changed_target_fetches':len(f),
            'changed_p_g_events':len(events),
            'changed_read_events':len(evidence_reads),
            'changed_stdout_tokens':receipt['stdout_tokens'],
            'changed_halt':True,'stage1_accepted':False,
            'scope':'ONE_INTERVENED_NATIVE_CASE_NOT_NATURAL_REACHABILITY'}


def detached_attacks(receipt, changed, signed, prior):
    attacks = [
        ('project', 'project_id', 'OTHER'),
        ('kind', 'kind', 'NATURAL_INPUT'),
        ('source', 'source_git_blob_sha1', '0'*40),
        ('stdin', 'stdin_hex', '00'),
        ('original_trace', 'old_signed_trace_sha256', '0'*64),
        ('single_fire', 'single_interception_hits', 2),
        ('status', 'status', 'STEP_LIMIT'),
        ('cap', 'cap', 1),
        ('steps', 'steps', len(changed)+1),
        ('stage_claim', 'stage1_accepted', True),
        ('stdout', 'stdout_tokens', ['FORGED']),
        ('reads', 'read_events', []),
    ]
    bad = []
    for label,key,value in attacks:
        forged=copy.deepcopy(receipt)
        forged[key]=value
        try:
            verify(forged,changed,signed,prior)
        except (AssertionError, TypeError, KeyError, ValueError):
            bad.append(label)
        else:
            raise AssertionError('forgery accepted '+label)
    traces = [
        ('before_writer', WRITER-2, 'ip', [42, 42]),
        ('writer_value', WRITER-1, 'pre', [62,1500,1860]),
        ('writer_successor', WRITER-1, 'next', [42,42]),
        ('dynamic_opcode', FETCH-1, 'op', 62),
        ('dynamic_successor', FETCH-1, 'next', [1501,1860]),
        ('changed_read', 291, 'reads', [{'forged':True}]),
    ]
    for label,index,key,value in traces:
        forged=list(changed)
        row=dict(forged[index]);row[key]=value;forged[index]=row
        try:
            verify(receipt,forged,signed,prior)
        except (AssertionError, TypeError, KeyError, ValueError):
            bad.append(label)
        else:
            raise AssertionError('altered STEP forgery accepted '+label)
    need(len(bad) >= 12, 'independent hostile rejection coverage')
    return bad


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--original-artifact', type=Path, required=True)
    p.add_argument('--source', type=Path, required=True)
    p.add_argument('--changed-dir', type=Path, required=True)
    p.add_argument('--report', type=Path, required=True)
    args=p.parse_args()
    original,signed,prior=read_controls(args.original_artifact,args.source)
    receipt=json.loads((args.changed_dir/'qa31ca_changed_receipt.json').read_bytes())
    packed=(args.changed_dir/'qa31ca_changed_once.jsonl.gz').read_bytes()
    need(receipt.get('trace') == 'qa31ca_changed_once.jsonl.gz' and
         receipt.get('trace_sha256') == sha(packed), 'changed compressed full trace SHA')
    rows=trace(packed)
    summary=verify(receipt,rows,signed,prior)
    bad=detached_attacks(receipt,rows,signed,prior)
    summary.update({'independent_detached_hostiles_rejected':len(bad),
                    'hostile_cases':bad,
                    'original_artifact_sha256':QA31CA_ARTIFACT_SHA,
                    'changed_trace_sha256':sha(packed),
                    'differential_gate':'FINITE_NATIVE_ONE_INTERVENTION_PASS_NOT_STAGE1'})
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n')
    print(json.dumps(summary,sort_keys=True))


if __name__ == '__main__':
    main()
