#!/usr/bin/env python3
"""QA31BV: independently bounded Funge-98 storage-offset audit of signed original traces.

Reads pre-existing immutable Native receipts only. Does not execute/modify the
Befunge program, certify an altered route, or establish Stage1 acceptance.
Usage: python qa31bv_original_storage_offset_audit.py --inputs DIR --output DIR
Python 3.11+, standard library only.
"""
from __future__ import annotations
import argparse, bisect, collections, copy, gzip, hashlib, io, json, pathlib, zipfile

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE = '560d6aa5807a7f766213a33835cce85eab0fa40c'
PINS = {
    'AI': ('QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip', '9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49'),
    'BN': ('QA31BN_BEFUNGE98_KYRGYZ_SIGNED_MINUS_ONE_20261120.zip', '6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79'),
    'BO': ('QA31BO_BEFUNGE98_KYRGYZ_POST_SECOND_SINK_20261120.zip', 'b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de'),
    'BT': ('QA31BT_BEFUNGE98_KYRGYZ_REMAINING_DOWNWARD_ORIGINAL_20261121.zip', 'faacb845cadc7554766ccff76d52a970aea10b775ed97ff20a306cb9c3dbabf6'),
    'BP': ('QA31BP_BEFUNGE98_KYRGYZ_ORIGINAL_EXECUTABLE_OWNER_20261120.zip', 'd0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24'),
    'AH': (None, '4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271'),
    'Y': (None, '1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a'),
}

def require(ok, msg):
    if not ok: raise AssertionError(msg)

def sha(b): return hashlib.sha256(b).hexdigest()

def verified_zip(blob, label):
    require(sha(blob) == PINS[label][1], f'{label} SHA mismatch')
    z=zipfile.ZipFile(io.BytesIO(blob))
    require(z.testzip() is None, f'{label} ZIP CRC failure')
    return z

def manifest(z, name):
    doc=json.loads(z.read(name))
    require(doc.get('project_id') == PROJECT, name+' wrong project')
    for filename,expected in doc['files'].items():
        require(sha(z.read(filename)) == expected, f'{name}: {filename} digest')
    return doc

def op(e):
    if e['string']: return None
    k=e['op']
    require(type(k) is int and 0<=k<128, 'non-ASCII opcode')
    return chr(k)

def paired(e):
    ip=e['ip']; delta=e['delta']
    require(isinstance(ip,list) and isinstance(delta,list) and len(ip)==2 and len(delta)==2 and
            all(type(v)==int for v in ip+delta), 'malformed IP/delta')
    return (ip[0]+delta[0], ip[1]+delta[1])

# Oracle F: chronological stack of prior offsets.
def forward_all(events):
    storage=(0,0); saved=[]; target=[]; change=[]
    for e in events:
        k=op(e)
        if k in ('g','p') or e['ip'] in ([1500,1860],[1500,1881]):
            target.append((e['t'],k,tuple(e['ip']),storage))
        if k=='{':
            saved.append(storage); storage=paired(e); change.append((e['t'],'{',storage))
        elif k=='}':
            require(saved, 'unbalanced original }')
            storage=saved.pop(); change.append((e['t'],'}',storage))
    require(not saved, 'unterminated original block; offset after scope UNKNOWN')
    return target,change

# Oracle R: backward block-balance reconstruction from a sparse brace ledger.
# Does not use any forward offset values or the forward saved-stack state.
def reverse_at(changes, ticks, tick):
    cursor=bisect.bisect_left(ticks,tick)-1
    depth=0
    while cursor>=0:
        e=changes[cursor]; k=op(e)
        if k=='}': depth+=1
        elif k=='{':
            if depth: depth-=1
            else: return paired(e)
        cursor-=1
    require(depth==0, 'unmatched original } in reverse prefix')
    return (0,0)

def reverse_selected(events, targets):
    braces=[e for e in events if op(e) in ('{','}')]
    ticks=[e['t'] for e in braces]
    return [(t,k,ip,reverse_at(braces,ticks,t)) for t,k,ip,_ in targets],len(braces)

def check_steps(events, case):
    require(case['status']=='HALT' and case['error'] is None, 'non-HALT receipt')
    require(len(events)==case['steps'] and case['steps']<=25000, 'signed STEP total drift')
    for i,e in enumerate(events,1):
        require(e['t']==i and e['string'] is False, 'non-contiguous physical tick/string mode')
        require(len(e['ip'])==len(e['delta'])==2, 'bad IP vector')
        if i<len(events):
            require(isinstance(e['next'],list) and len(e['next'])==2, 'nonterminal next IP missing')
            require(e['next']==events[i]['ip'], 'next IP/physical STEP mismatch')
        else:
            require(e['next'] is None or (isinstance(e['next'],list) and len(e['next'])==2), 'invalid HALT next IP')

# Decoupled integrity guards, never modifications of original signed evidence.
def detached_hostiles(case, raw_compressed, events, source_pin):
    require(sha(raw_compressed)==case['trace_sha256'], 'initial digest mismatch')
    original={"receipt":copy.deepcopy(case),"compressed":raw_compressed,"source":source_pin}
    tests=[]
    def accepts(x):
        r=x['receipt']
        require(x['source']==SOURCE,'source mutation')
        require(r.get('status')=='HALT' and r.get('error') is None,'status mutation')
        require(r.get('steps')==len(events),'step-count mutation')
        require(r.get('label')==case['label'],'label mutation')
        require(r.get('trace_sha256')==case['trace_sha256'],'signed trace hash mutation')
        require(sha(x['compressed'])==case['trace_sha256'],'compressed-byte mutation')
        require(r.get('output')==case['output'],'output mutation')
        require(r.get('raw_sha256')==case['raw_sha256'],'stdin hash mutation')
        require(r.get('raw_hex')==case['raw_hex'],'stdin bytes mutation')
        require(r.get('reads')==case['reads'],'read count mutation')
        return True
    edits=[('source_pin',lambda x:x.update(source='0'*40)),
           ('receipt_status',lambda x:x['receipt'].update(status='TIMEOUT')),
           ('receipt_error',lambda x:x['receipt'].update(error='fake')),
           ('receipt_steps',lambda x:x['receipt'].update(steps=x['receipt']['steps']+1)),
           ('receipt_label',lambda x:x['receipt'].update(label='forged')),
           ('receipt_sha',lambda x:x['receipt'].update(trace_sha256='0'*64)),
           ('receipt_output',lambda x:x['receipt'].update(output=['forged'])),
           ('receipt_reads',lambda x:x['receipt'].update(reads=-1)),
           ('receipt_raw_hex',lambda x:x['receipt'].update(raw_hex='00')),
           ('receipt_raw_sha',lambda x:x['receipt'].update(raw_sha256='0'*64)),
           ('trace_flip_first',lambda x:x.update(compressed=bytes([x['compressed'][0]^1])+x['compressed'][1:])),
           ('trace_flip_middle',lambda x:x.update(compressed=x['compressed'][:len(x['compressed'])//2]+bytes([x['compressed'][len(x['compressed'])//2]^1])+x['compressed'][len(x['compressed'])//2+1:])),
           ('trace_drop_last',lambda x:x.update(compressed=x['compressed'][:-1])),
           ('trace_append_byte',lambda x:x.update(compressed=x['compressed']+b'X')),
           ('receipt_missing_status',lambda x:x['receipt'].pop('status')),
           ('receipt_missing_step',lambda x:x['receipt'].pop('steps'))]
    for name,mut in edits:
        x=copy.deepcopy(original); mut(x)
        try: accepts(x)
        except (AssertionError,KeyError): tests.append({'case':case['label'],'test':name,'rejected':True})
        else: raise AssertionError('hostile accepted: '+name)
    require(accepts(original),'unchanged original checkpoint rejected')
    return tests

def synthetic_reverse_forward():
    def e(t,c,ip,delta):return {'t':t,'op':ord(c),'string':False,'ip':list(ip),'delta':list(delta)}
    fixture_sets=[
      [e(1,'0',(0,0),(1,0))],
      [e(1,'{',(5,5),(1,0)),e(2,'g',(6,5),(1,0)),e(3,'}',(7,5),(1,0))],
      [e(1,'{',(5,5),(1,0)),e(2,'{',(9,8),(0,1)),e(3,'p',(9,9),(1,0)),e(4,'}',(1,1),(1,0)),e(5,'g',(2,1),(1,0)),e(6,'}',(3,1),(1,0)),e(7,'p',(4,1),(1,0))],
      [e(1,'{',(-10,8),(0,-1)),e(2,'g',(-10,7),(1,0)),e(3,'}',(-9,7),(1,0)),e(4,'p',(-8,7),(1,0))],
    ]
    pairs=0
    for records in fixture_sets:
        f,_=forward_all(records)
        r,_=reverse_selected(records,f)
        require(f==r,'independent synthetic SO oracle mismatch')
        pairs+=len(f)
    return {'synthetic_oracle_fixtures':len(fixture_sets),'synthetic_oracle_target_agreements':pairs}

def execute(inputs, output):
    output.mkdir(parents=True,exist_ok=False)
    data={k:(inputs/PINS[k][0]).read_bytes() for k in ('AI','BN','BO','BT','BP')}
    with verified_zip(data['BN'],'BN') as bn,verified_zip(data['BO'],'BO') as bo,verified_zip(data['BT'],'BT') as bt,verified_zip(data['BP'],'BP') as bp:
        for z in (bn,bo,bt,bp):manifest(z,'MANIFEST.json')
        noops=[json.loads(x) for x in bn.read('evidence/qa31bn_noops.jsonl').splitlines() if x.strip()]
        require(len(noops)==24 and all(x['classification']=='NO_NUMERIC_EFFECT' and x['original_g']==x['intervention_g'] and x['forward_sinks']==x['baseline_sinks'] for x in noops),'original control baseline mismatch')
    with verified_zip(data['AI'],'AI') as ai:
        ah_bytes=ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip')
        with verified_zip(ah_bytes,'AH') as ah: y_bytes=ah.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip')
    counts=collections.Counter(); source_changes=collections.Counter(); rows=[]; controls=[]; hostile=[]; receipt_cases={}; observed_noop_cases=set(); unique_signed_controls=set()
    with verified_zip(y_bytes,'Y') as original:
        ym=manifest(original,'QA31Y_MANIFEST.json')
        for shard in range(8):
            name=f'QA31V_SHARD{shard}.zip'
            bb=original.read(name)
            require(sha(bb)==ym['files'][name],'original shard manifest mismatch')
            with zipfile.ZipFile(io.BytesIO(bb)) as z:
                require(z.testzip() is None,f'original shard{shard} CRC mismatch')
                receipt=json.loads(z.read('qa31v_receipt.json'))
                require(receipt['source_blob']==SOURCE and receipt['shard']==shard and len(receipt['cases'])==25,'original source/shard lock mismatch')
                for case in receipt['cases']:
                    require(case['label'] not in receipt_cases,'duplicate signed case')
                    packed=z.read(case['trace'])
                    require(sha(packed)==case['trace_sha256'],'original signed trace hash drift')
                    events=[json.loads(line) for line in gzip.decompress(packed).splitlines() if line.strip()]
                    check_steps(events,case)
                    chronological,changes=forward_all(events)
                    reverse,num_braces=reverse_selected(events,chronological)
                    require(chronological==reverse,'forward/reverse signed SO disagreement')
                    require(num_braces==0,'original unexpected storage-offset transition; inspect independently')
                    require(all(t[3]==(0,0) for t in chronological),'nonzero offset in original zero-brace corpus')
                    pc=collections.Counter(k if k in ('p','g') else 'fetch_'+str(ip[1]) for _,k,ip,_ in chronological)
                    counts.update({'receipts':1,'steps':len(events),'p':pc['p'],'g':pc['g'],'fetch_1860':pc['fetch_1860'],'fetch_1881':pc['fetch_1881'],'offset_events':num_braces,'oracle_site_agreements':len(chronological)})
                    if not any(k=='g' for _,k,_,_ in chronological):source_changes['no_g_cases']+=1
                    receipt_cases[case['label']]=case['trace_sha256']
                    rows.append({'case':case['label'],'trace_sha256':case['trace_sha256'],'steps':len(events),'g':pc['g'],'p':pc['p'],'source_fetch_1500_1860':pc['fetch_1860'],'source_fetch_1500_1881':pc['fetch_1881'],'storage_offset_at_observed_sites':[0,0], 'unvisited_fetch_storage_offset':'UNKNOWN'})
                    if len(unique_signed_controls)<12 and case['label'] not in unique_signed_controls:
                        unique_signed_controls.add(case['label'])
                        controls.append({'type':'original_signed_unmodified','case':case['label'],'trace_sha256':case['trace_sha256'],'steps':case['steps'],'site_agreements':len(chronological)})
                    if not hostile: hostile=detached_hostiles(case,packed,events,SOURCE)
        require(counts['receipts']==200 and counts['steps']==3628390,'200 original HALT identity drift')
        require(counts['p']==14820 and counts['g']==27395,'original p/g count drift')
        require(counts['fetch_1860']==140 and counts['fetch_1881']==0,'bounded original fetch count drift')
        require(len(controls)==12 and len(hostile)>=12,'QA control minimum unmet')
        for item in noops:
            require(receipt_cases.get(item['case'])==item['trace_sha256'],'no-op receipt not signed original')
            observed_noop_cases.add(item['case'])
            controls.append({'type':'genuine_signed_original_no_numeric_effect','case':item['case'],'trace_sha256':item['trace_sha256'],'root_tick':item['root_tick']})
        require(len(observed_noop_cases)==6,'wrong original no-op case count')
    syn=synthetic_reverse_forward()
    summary={'project_id':PROJECT,'qa':'QA31BV','source_blob':SOURCE,'signed_input_sha256':{k:PINS[k][1] for k in PINS},'signed_original_halt_receipts':counts['receipts'],'signed_original_steps':counts['steps'], 'physically_observed_original_storage_offset_transitions':counts['offset_events'], 'original_p_sites':counts['p'],'original_g_sites':counts['g'],'original_fetch_1500_1860':counts['fetch_1860'],'original_fetch_1500_1881':counts['fetch_1881'],'independent_chronological_reverse_site_agreements':counts['oracle_site_agreements'],'site_so':[0,0], 'unvisited_fetch_SO':'UNKNOWN','signed_unchanged_distinct_original_cases':len(unique_signed_controls), 'signed_genuine_no_numeric_effect_rows':len(noops),'signed_genuine_no_numeric_effect_distinct_cases':len(observed_noop_cases),'detached_hostile_rejected':len(hostile),**syn,'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False, 'altered_run_so_path_writers_stack_output':'UNKNOWN'}
    (output/'qa31bv_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2,sort_keys=True)+'\n')
    for filename,data in (('qa31bv_cases.jsonl',rows),('qa31bv_original_controls.jsonl',controls),('qa31bv_detached_hostiles.jsonl',hostile)):
        (output/filename).write_text(''.join(json.dumps(r,sort_keys=True,ensure_ascii=False)+'\n' for r in data))
    print(json.dumps(summary,indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--inputs',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args();execute(a.inputs,a.output)
