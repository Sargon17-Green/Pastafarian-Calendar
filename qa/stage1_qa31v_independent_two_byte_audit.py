#!/usr/bin/env python3
"""QA31V independent original Native two-byte corpus and full-STEP audit."""
import argparse, hashlib, json
from pathlib import Path
from stage1_qa31t_independent_frontier_audit import audit_trace, gitblob, need
import stage1_qa31u_independent_suffix_audit as finite_controls

PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
PREFIX=b'1 0 0 0'
DIGITS=tuple(range(0x30,0x3a))
SPECIAL=(0,9,10,13,32,255)
WS=(9,10,13,32)
CAP,SIZE,SHARDS=25000,25,8

def cases(shard):
    need(type(shard) is int and 0<=shard<SHARDS,'shard index')
    a=[(x,y) for x in DIGITS for y in DIGITS+SPECIAL]
    b=[(x,y) for x in WS for y in DIGITS]
    all_pairs=a+b
    need(len(a)==160 and len(b)==40 and len(set(all_pairs))==200,
         'independent corpus cardinality/uniqueness')
    selected=all_pairs[shard*SIZE:(shard+1)*SIZE]
    need(len(selected)==SIZE,'independent shard size')
    return [('pair_%02x_%02x' % (x,y),PREFIX+bytes((x,y)))
            for x,y in selected]

def digest(raw):
    return hashlib.sha256(raw).hexdigest()

def verify_receipt(doc,shard):
    need(type(doc) is dict and
         doc.get('schema')=='qa31v-original-native-two-byte-v1'
         and doc.get('source_blob')==PIN
         and doc.get('source_modified') is False
         and doc.get('ip_relocated') is False
         and doc.get('suffix_prefix_hex')==PREFIX.hex()
         and doc.get('suffix_length')==2
         and doc.get('corpus_size')==200
         and doc.get('corpus_definition')=='digit_x_digit_or_special_then_ws_x_digit'
         and type(doc.get('shard')) is int and doc['shard']==shard
         and doc.get('shard_size')==SIZE
         and doc.get('total_shards')==SHARDS
         and doc.get('case_cap_steps')==CAP
         and doc.get('all_shards_step_cap')==CAP*SIZE*SHARDS
         and doc.get('completed_native_cases')==SIZE
         and doc.get('global_reachability_proven') is False
         and doc.get('stage1_pass') is False,
         'receipt schema, provenance, bounds or scope')
    recs=doc.get('cases')
    need(type(recs) is list and len(recs)==SIZE,'receipt case count')
    for (label,raw),rec in zip(cases(shard),recs):
        need(type(rec) is dict and rec.get('label')==label
             and rec.get('raw_hex')==raw.hex()
             and rec.get('raw_sha256')==digest(raw)
             and rec.get('trace')=='qa31g_'+label+'.jsonl.gz'
             and type(rec.get('trace_sha256')) is str
             and len(rec['trace_sha256'])==64
             and type(rec.get('steps')) is int and 0<rec['steps']<=CAP
             and type(rec.get('reads')) is int and rec['reads']>=0
             and rec.get('status')=='HALT' and rec.get('error') is None
             and type(rec.get('output')) is list,
             'case mismatch: exact Native HALT/input/trace')

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('source')
    ap.add_argument('folder')
    ap.add_argument('shard',type=int)
    args=ap.parse_args()
    source=Path(args.source).read_bytes()
    need(gitblob(source)==PIN,'original Git blob')
    rows=source.splitlines()
    need(len(rows)==2015 and rows[49]==b'','original geometry')
    folder=Path(args.folder)
    doc=json.loads((folder/'qa31v_receipt.json').read_bytes())
    verify_receipt(doc,args.shard)
    audited=[]
    summaries=[]
    for (label,raw),rec in zip(cases(args.shard),doc['cases']):
        result=audit_trace(rec,raw,rows,folder)
        result.pop('_picked')
        need(result['status']=='HALT' and result['steps']==rec['steps'],
             'full physical STEP/HALT mismatch')
        audited.append(result)
        summaries.append({
            'label':label,'raw_hex':raw.hex(),
            'steps':result['steps'],'reads':result['stdin_reads'],
            'eof_reads':result['eof_reads'],
            'm29':[g['read'] for g in result['gates']
                   if g['kind']=='m29' and g['target']==[3,49]],
            'q32_q38':[[g['kind'],g['read']] for g in result['gates']
                      if g['kind'] in ('q32','q38') and g['target']==[1,49]],
            'j_operands':[[j['kind'],j['operand']] for j in result['jumps']],
            'x_kinds':[x['kind'] for x in result['exits']],
            'frontier_hits':[p for p,t in result['frontier_first_ticks'].items()
                             if t is not None],
        })
        print('QA31V_AUDITED',args.shard,label,result['steps'])
    # Reuse the previously accepted 11 receipt plus 7 physical hostile cases,
    # rebinding ONLY the QA receipt validator inside this independent audit process.
    finite_controls.verify_receipt=verify_receipt
    rejects=finite_controls.adversarial(
        doc,args.shard,doc['cases'][0],cases(args.shard)[0][1],rows,folder)
    ticks=sum(c['steps'] for c in audited)
    need(ticks<=SIZE*CAP and rejects==18,'shard bounds / forgeries')
    hits=sorted({p for c in audited for p,t in c['frontier_first_ticks'].items()
                 if t is not None})
    report={'schema':'qa31v-independent-original-native-two-byte-v1',
            'shard':args.shard,'source_blob':PIN,
            'cases_verified':SIZE,'physical_steps_verified':ticks,
            'hostile_controls_rejected':rejects,
            'finite_frontier_hits':hits,'summaries':summaries,
            'cases':audited,'global_reachability_proven':False,
            'stage1_pass':False}
    (folder/'qa31v_independent.json').write_text(
        json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('QA31V_SHARD_FULL_TRACE_AUDITED',args.shard,ticks)
    print('QA31V_SHARD_HOSTILE_CONTROLS',args.shard,rejects,'OF_18_REJECTED')
    print('QA31V_SHARD_FINITE_FRONTIER_HITS',args.shard,hits)
    print('QA31V_STAGE1_REMAINS_OPEN')

if __name__=='__main__':
    main()
