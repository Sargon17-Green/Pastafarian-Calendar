#!/usr/bin/env python3
"""QA31CE finite causal comparison: original signed QA31CB+QA31CD traces.

No interpreter execution, no source modification, no GitHub/CI requests. Python stdlib.
Usage: python3 qa31ce_existing_four_trace_causal_audit.py QA31CB.zip QA31CD.zip [--output review.json]
"""
import argparse
import gzip
import hashlib
import io
import json
import sys
import zipfile
from collections import Counter
from pathlib import Path

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
ARTIFACTS = {
    'CB': ('ea247b7c907d9cd0e1fb8e211619ff538b99b435dd43bcdaef70f084f6e499be', 'qa31cb_artifact_manifest.json'),
    'CD': ('a8a48737663cdcfcae6df4c93bc62dde81f02c5159803a7d3484aee7363c9db1', 'qa31cd_artifact_manifest.json'),
}
TRACES = {
    (0, 100): ('CB', 'token_100.jsonl.gz'),
    (0, 999): ('CB', 'token_999.jsonl.gz'),
    (1, 100): ('CD', 'candidate_100.jsonl.gz'),
    (1, 999): ('CD', 'candidate_999.jsonl.gz'),
}
# These are the same physical coordinates in four archived independently run Native records.
EVENTS = {
    'last_token_store': (10614, (384, 575), 112, (11, 1693)),
    'third_token_store': (10629, (369, 575), 112, (7, 1692)),
    'second_token_store': (10664, (860, 846), 112, (5, 1691)),
    'second_token_load': (10900, (100, 1057), 103, (5, 1691)),
    'owner_store': (11135, (1332, 480), 112, (19, 1696)),
    'owner_load': (24722, (677, 765), 103, (19, 1696)),
    'code_store': (24795, (96, 480), 112, (1500, 1860)),
}
GATE = (33, 42, 33, 42)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_zip(path, label):
    raw = Path(path).read_bytes()
    expected, manifest_name = ARTIFACTS[label]
    require(sha256(raw) == expected, label + ': archive SHA256 mismatch')
    z = zipfile.ZipFile(io.BytesIO(raw), 'r')
    bad = z.testzip()
    require(bad is None, label + ': zip CRC failed: ' + str(bad))
    manifest = json.loads(z.read(manifest_name))
    require(manifest.get('project_id') == PROJECT, label + ': wrong project')
    require(manifest.get('source_git_blob_sha1', SOURCE_BLOB) == SOURCE_BLOB, label + ': wrong source manifest')
    for member, digest in manifest['files'].items():
        require(member in z.namelist(), label + ': missing member ' + member)
        require(sha256(z.read(member)) == digest, label + ': member SHA mismatch: ' + member)
    meta = json.loads(z.read('qa31cb_source_cells.json'))
    require(meta['source_git_blob_sha1'] == SOURCE_BLOB, label + ': source blob mismatch')
    require(meta['project_id'] == PROJECT, label + ': source metadata project mismatch')
    return z, manifest


def parse_trace(z, name):
    blob = z.read(name)
    rows = []
    with gzip.GzipFile(fileobj=io.BytesIO(blob), mode='rb') as f:
        for line in f:
            rows.append(json.loads(line))
    require(rows, name + ': empty trace')
    for i, row in enumerate(rows):
        require(row['t'] == i + 1, name + ': nonmonotone tick')
        if i + 1 < len(rows):
            require(row['next'] == rows[i + 1]['ip'], name + ': broken IP continuity at '+str(i+1))
            require(row['next_delta'] == rows[i + 1]['delta'], name + ': broken delta continuity at '+str(i+1))
    require(rows[-1]['op'] == 64 and rows[-1]['next'] is None, name + ': no HALT')
    return rows


def identify_event(rows, tick, ip, op, target):
    r = rows[tick - 1]
    require(tuple(r['ip']) == ip and r['op'] == op, f'wrong opcode/IP at tick {tick}')
    pg = r.get('pg')
    require(pg is not None, f'missing p/g at tick {tick}')
    require(tuple(pg['target']) == target, f'wrong p/g target at tick {tick}')
    require(pg['storage_offset'] == [0, 0], f'nonzero storage offset at tick {tick}')
    pre = pg['pre_toss']
    require(tuple(pre[-2:]) == target, f'address not on stack at tick {tick}')
    if op == 112:
        require(pg['cell_after'] == pre[-3], f'p value not from stack at tick {tick}')
    else:
        require(pg['result'] == r['post'][-1] == pg['cell_before'], f'g not from stored cell at tick {tick}')
    return pg


def summarise(rows, b, n):
    require(rows[10579-1]['post'] == [1,b,0,n], 'original TOSS input prefix mismatch')
    ps={key: identify_event(rows,*spec) for key,spec in EVENTS.items()}
    require(ps['last_token_store']['cell_after'] == n, 'last token storage mismatch')
    require(ps['third_token_store']['cell_after'] == 0, 'third token mismatch')
    require(ps['second_token_store']['cell_after'] == b, 'second token storage mismatch')
    require(ps['second_token_load']['result'] == b, 'second token read mismatch')
    require(rows[10900-1]['post'] == [1,1,b], 'unexpected RPN pre-gate prefix')
    gate=rows[10901-1:10904]
    require(tuple(r['op'] for r in gate) == GATE, 'original gate opcodes mismatch')
    require(gate[0]['pre'] == [1,1,b], 'gate input mismatch')
    def not_op(x): return 1 if x == 0 else 0
    expected=1*not_op(1*not_op(b))
    require(gate[-1]['post'] == [expected], 'gate output mismatch')
    require(ps['owner_store']['cell_after'] == expected, 'owner store mismatch')
    require(ps['owner_load']['result'] == expected, 'owner read mismatch')
    code=56*expected+62
    require(ps['code_store']['cell_after'] == code, 'dynamic code store mismatch')
    fetch=rows[24823-1]
    require(fetch['ip']==[1500,1860] and fetch['op']==code, 'dynamic opcode fetch mismatch')
    require(fetch.get('fetch') and fetch['fetch']['cell_observed']==code, 'dynamic fetch receipt mismatch')
    require(fetch['next_delta'] == ([1,0] if code==62 else [0,1]), 'direction change mismatch')
    # Include full-sequence comparisons but never infer general source independence from them.
    reads=[x for row in rows for x in row['reads']]
    output=bytes.fromhex(''.join(row['stdout_delta_hex'] for row in rows))
    return {'input':f'1 {b} 0 {n}','steps':len(rows),'status':'HALT',
            'n_stored_at_11_1693':n,'b_stored_at_5_1691':b,
            'gate_pre_stack':[1,1,b],'owner_value':expected,
            'dynamic_stored_and_fetched':code,'fetch_next_delta':fetch['next_delta'],
            'reads':len(reads),'stdout_sha256':sha256(output), 'stdout_length':len(output),
            'source_body_sha':SOURCE_BLOB}


def first_difference(rows_a, rows_b, key):
    for i,(a,b) in enumerate(zip(rows_a,rows_b)):
        if key(a) != key(b):return i+1
    return None if len(rows_a)==len(rows_b) else min(len(rows_a),len(rows_b))+1


def check_four(traces):
    out={}
    summaries={}
    for (b,n),rows in traces.items():
        summaries[f'b{b}_n{n}']=summarise(rows,b,n)
    for n in (100,999):
        neg=traces[(0,n)];pos=traces[(1,n)]
        # Original instruction path shared up to and including the physically written code at 24795;
        # the fetch at 24823 is the first differing executed instruction.
        require(all(neg[i]['ip']==pos[i]['ip'] and neg[i]['op']==pos[i]['op'] for i in range(24822)), 'early op/IP divergence')
        require(first_difference(neg,pos,lambda x:(x['ip'],x['op']))==24823, 'first divergence not at dynamic fetch')
        out[f'fixed_n{n}_b0_to_b1']={
           'first_opcode_or_ip_divergence_tick':24823,
           'shared_opcode_ip_prefix_count':24822,
           'first_physical_stack_difference_tick':first_difference(neg,pos,lambda x:x['pre']),
           'old_owner_code_steps':[0,62,24853],
           'new_owner_code_steps':[1,118,24977],
           'different_input_position':'second integer token only',
           'proof_scope':'two original executed traces; not hypothetical instruction simulation'}
    for b in (0,1):
        lo=traces[(b,100)];hi=traces[(b,999)]
        require(len(lo)==len(hi), 'step count varies with n')
        require(first_difference(lo,hi,lambda x:(x['ip'],x['op'])) is None, 'route depends on n within tested pair')
        out[f'fixed_b{b}_n100_to_n999']={
           'shared_opcode_ip_route_count':len(lo),
           'first_physical_stack_difference_tick':first_difference(lo,hi,lambda x:x['pre']),
           'owner_and_code_unchanged':True,
           'different_input_position':'last integer token only'}
    return summaries,out


def negative_tests(traces):
    # Non-Native adversarial checks on detached signed trace RECORDS; mutation must be rejected.
    base=traces[(1,100)]
    import copy
    def expect_rejection(tag, mutate):
        rows=base[:]
        mutated=copy.deepcopy(rows[mutate[0]-1]); mutate[1](mutated)
        rows=rows[:mutate[0]-1]+[mutated]+rows[mutate[0]:]
        try: summarise(rows,1,100)
        except AssertionError: return tag
        raise AssertionError('hostile fake was accepted: '+tag)
    m=[
      ('forge_last_n_write',(10614,lambda r:r['pg'].__setitem__('cell_after',999))),
      ('forge_second_b_write',(10664,lambda r:r['pg'].__setitem__('cell_after',0))),
      ('forge_second_b_read',(10900,lambda r:r['pg'].__setitem__('result',0))),
      ('forge_gate_op',(10902,lambda r:r.__setitem__('op',43))),
      ('forge_owner_write',(11135,lambda r:r['pg'].__setitem__('cell_after',0))),
      ('forge_owner_read',(24722,lambda r:r['pg'].__setitem__('result',0))),
      ('forge_code_write',(24795,lambda r:r['pg'].__setitem__('cell_after',62))),
      ('forge_dynamic_fetch',(24823,lambda r:r.__setitem__('op',62))),
    ]
    return [expect_rejection(tag,spec) for tag,spec in m]


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('cb_zip');ap.add_argument('cd_zip');ap.add_argument('--output')
    args=ap.parse_args()
    za,ma=read_zip(args.cb_zip,'CB');zb,mb=read_zip(args.cd_zip,'CD')
    archives={'CB':za,'CD':zb};manifests={'CB':ma,'CD':mb}
    traces={}
    for key,(lab,name) in TRACES.items():
        require(name in manifests[lab]['files'], 'retained trace absent from pinned manifest')
        traces[key]=parse_trace(archives[lab],name)
    summaries,paired=check_four(traces)
    negative=negative_tests(traces)
    result={'schema':'qa31ce-original-native-four-trace-causal-comparison-v1',
       'project_id':PROJECT,'source_blob_sha1':SOURCE_BLOB,'stage1_accepted':False,
       'native_executions_new':0,'ci_runs_new':0,
       'inputs_covered':list(summaries.keys()),'steps_physically_inspected':sum(map(len,traces.values())),
       'archive_sha256':{k:v[0] for k,v in ARTIFACTS.items()},
       'archive_crc_and_manifest_sha':'PASS',
       'cases':summaries,'paired_checks':paired,
       'hostile_detached_mutations_rejected':len(negative),'hostile_names':negative,
       'conclusion': 'For fixed n, changing second token b=0 -> 1 changes owner 0 -> 1 and code 62 -> 118 on a common 24822 opcode/IP prefix; changing n=100 -> 999 at fixed b leaves route, owner, and code unchanged for four finite traces only.'}
    body=json.dumps(result,ensure_ascii=False,sort_keys=True,indent=2)+'\n'
    if args.output:Path(args.output).write_text(body,encoding='utf-8')
    print('QA31CE_FINITE_OFFLINE_AUDIT_PASS cases=4 STEPs='+str(result['steps_physically_inspected'])+' hostile=8/8 new_native=0 global_stage1=OPEN')
    print('QA31CE_RESULT_SHA256 '+sha256(body.encode('utf-8')))
    print('QA31CE_PAIRS '+json.dumps(paired,sort_keys=True))

if __name__=='__main__':
    try:main()
    except (AssertionError,KeyError,ValueError,zipfile.BadZipFile,EOFError) as err:
        print('QA31CE_OFFLINE_AUDIT_FAILURE '+str(err),file=sys.stderr)
        sys.exit(2)
