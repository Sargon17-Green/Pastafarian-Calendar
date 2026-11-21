#!/usr/bin/env python3
"""QA31BL: exact-integer signed g-to-overwrite audit, finite original corpus only.

Two independent oracles:
  A. forward runtime-stack arithmetic + observed memory ownership;
  B. backward stack-slot expression expansion from overwrite-value operands.
Both operate on pinned original physical STEP events, not predicted Native traces.
The modulo operand in observed `%` operations is M=2**127-1; Python's
nonnegative residue for a positive divisor is checked as an explicit gate.
No new Native, no claim of input-intervention causality or Stage1 acceptance.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from functools import lru_cache
import copy
import gzip
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
M = (1 << 127) - 1
PINS = {
    'AI':'9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49',
    'AH':'4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271',
    'Y':'1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a',
    'BI':'7660413b191784de8ec4f54ee51aea66c509a6726ea30f19401432a2816733d2',
    'BJ':'cba7da292cf8d595a5a680743ea29ca3642299bd9aecd62094fb8f42652251c3',
    'BK':'16aa91dfc48b0329d396d311dc7f68d826286484debc9024deeca78e12a9f9e2',
}
FIRST = {(1057,290):(103,1715),(1430,1540):(107,1716)}
SECOND = {(195,1036):(103,1715),(1328,860):(107,1716)}
READ_IPS = {(1335,747),(1140,1335),(480,950),(670,1334)}


def need(test, why):
    if not test: raise ValueError(why)

def digest(b): return hashlib.sha256(b).hexdigest()

def original_zip(b, label):
    need(digest(b) == PINS[label], 'PIN SHA256 '+label)
    z=zipfile.ZipFile(io.BytesIO(b))
    need(z.testzip() is None and len(z.namelist())==len(set(z.namelist())), 'ZIP CRC/duplicates '+label)
    return z

def truncate_zero(a,b):
    if b==0:return 0
    q=abs(a)//abs(b)
    return -q if (a<0) != (b<0) else q

def forward_op(op,pre,ev):
    """Oracle A: independent full-stack concrete transition, no floating point."""
    s=list(pre)
    if op in '0123456789abcdef':s.append(int(op,16))
    elif op in '+-*/%`':
        need(len(s)>=2,'A_NUMERIC underflow '+str(ev['t']))
        b=s.pop();a=s.pop()
        if op=='+':v=a+b
        elif op=='-':v=a-b
        elif op=='*':v=a*b
        elif op=='/':v=truncate_zero(a,b)
        elif op=='%':v=a%b if b else 0
        else:v=int(a>b)
        s.append(v)
    elif op=='!':
        need(s,'A_NUMERIC unary underflow');s.append(int(s.pop()==0))
    elif op==':':
        need(s,'A_NUMERIC duplicate underflow');s.append(s[-1])
    elif op=='\\':
        need(len(s)>=2,'A_NUMERIC swap underflow');s[-1],s[-2]=s[-2],s[-1]
    elif op in '$.,_|j':
        need(s,'A_NUMERIC drop underflow');s.pop()
    elif op in 'xw':
        need(len(s)>=2,'A_NUMERIC vector underflow');s.pop();s.pop()
    elif op=='p':
        need(len(s)>=3,'A_NUMERIC put underflow');del s[-3:]
    elif op=='g':
        need(len(s)>=2,'A_NUMERIC get underflow');del s[-2:];s.append(ev['post'][-1])
    elif op=='k':
        need(ev['ip']==[1475,101] and len(s)>=3 and s[-1]==1,
             'A_NUMERIC unsupported iteration')
        s[-3:]=[s[-3]+s[-2]]
    elif op in '<>^v#[]rz@" ': pass
    else:raise ValueError('A_NUMERIC unsupported opcode '+repr(op)+' at '+str(ev['t']))
    return s


def physical(rows):
    need(0<len(rows)<=25000 and rows[-1]['op']==64 and rows[-1]['next'] is None,'physical HALT/limit')
    for i,e in enumerate(rows):
        need(e['t']==i+1 and isinstance(e['string'],bool),'physical tick/string')
        if i:
            p=rows[i-1]
            need((p['next'],p['next_delta'],p['post'])==(e['ip'],e['delta'],e['pre']),
                 'physical STEP linkage at '+str(e['t']))


def oracle_a(rows, witness):
    """Replay every numeric STEP between first relevant g and second overwritten p."""
    puts=sorted(witness['puts'],key=lambda x:x['tick'])
    start=min(r['tick'] for p in puts for r in p['g_reads']);end=max(p['tick'] for p in puts)
    memory={tuple(p['address']):(p['tick'],p['value']) for p in puts if p['tick']<start}
    s=list(rows[start-1]['pre']);checks=Counter();arithmetic=[];reads=[];writes=[]
    for t in range(start,end+1):
        e=rows[t-1];op=chr(e['op'])
        need(e['pre']==s,'A_NUMERIC signed pre mismatch at '+str(t))
        if op=='g':
            addr=tuple(s[-2:]); owner=memory.get(addr)
            if owner is not None:
                need(e['post'][-1]==owner[1], 'A_NUMERIC last writer mismatch at '+str(t))
                reads.append((t,addr,owner[0],owner[1]))
        if op=='p':
            addr=tuple(s[-2:]);writes.append((t,addr,s[-3]));memory[addr]=(t,s[-3])
        if op=='%':
            need(len(s)>=2,'A_NUMERIC modulo pre')
            if s[-1]==M:
                checks['mod_M']+=1
                need(0<=s[-2]%M<M,'A_NUMERIC modulo residue range')
        updated=forward_op(op,s,e)
        need(updated==e['post'],'A_NUMERIC arithmetic/transition mismatch at '+str(t)+' '+op)
        if op in '+-*/%`!k':
            arithmetic.append({'tick':t,'op':op,'pre_tail':s[-3:],'actual_post_top':e['post'][-1],
                               'A_value':updated[-1]})
            checks['arithmetic']+=1
        checks['steps']+=1;s=updated
    expected_reads={(r['tick'],tuple(p['address']),p['tick'],r['value'])
                    for p in puts for r in p['g_reads']}
    need(len(reads)==4 and set(reads)==expected_reads,'A_NUMERIC owner-read signed witnesses')
    need(len(writes)==3,'A_NUMERIC finite observed read/write count')
    return {'start':start,'end':end,'read_events':reads,'write_events':writes,
            'checks':dict(checks),'numeric_steps':arithmetic}


def oracle_b(rows,witness):
    """Oracle B: reconstruct final put operands backwards from physical stack slots.

    Uses a different arithmetic implementation and no Oracle A stack state/memory.
    Missing or unsupported source paths fail closed; signed other g reads are
    treated as observed inputs, not reconstructed independent memory origins.
    """
    starts=[r['tick'] for p in witness['puts'] for r in p['g_reads']]
    first=min(starts)
    roots=set(starts)
    seen_steps={}
    sys.setrecursionlimit(max(sys.getrecursionlimit(),30000))

    @lru_cache(maxsize=None)
    def solve(t,slot):
        need(t>=first-1,'B_NUMERIC backward bound')
        if t==first-1:
            pre=rows[first-1]['pre']
            need(0<=slot<len(pre),'B_NUMERIC initial boundary slot')
            return pre[slot],frozenset()
        e=rows[t-1];op=chr(e['op']);pre=e['pre'];post=e['post']
        need(0<=slot<len(post),'B_NUMERIC output slot at '+str(t))
        # Explicit pre/post transition arity; no imported forward oracle.
        if op in '0123456789abcdef': n=0; k=1
        elif op in '+-*/%`':n=2;k=1
        elif op=='!':n=1;k=1
        elif op==':':n=1;k=2
        elif op=='\\':n=2;k=2
        elif op in '$.,_|j':n=1;k=0
        elif op in 'xw':n=2;k=0
        elif op=='p':n=3;k=0
        elif op=='g':n=2;k=1
        elif op=='k' and e['ip']==[1475,101] and pre[-1]==1:n=3;k=1
        elif op in '<>^v#[]rz@" ':n=0;k=0
        else:raise ValueError('B_NUMERIC unsupported '+repr(op)+' at '+str(t))
        need(len(post)==len(pre)-n+k,'B_NUMERIC arity mismatch at '+str(t))
        base=len(pre)-n
        if slot<base:
            result=solve(t-1,slot)
        elif op in '0123456789abcdef':result=(int(op,16),frozenset())
        elif op=='g':result=(post[-1],frozenset((t,)) if t in roots else frozenset())
        elif op==':':result=solve(t-1,len(pre)-1)
        elif op=='\\':result=solve(t-1,len(pre)-1 if slot==base else len(pre)-2)
        elif op=='!':
            x,r=solve(t-1,len(pre)-1);result=(0 if x else 1,r)
        elif op in '+-*/%`':
            a,ra=solve(t-1,len(pre)-2);b,rb=solve(t-1,len(pre)-1)
            if op=='+':v=a+b
            elif op=='-':v=a-b
            elif op=='*':v=a*b
            elif op=='/':v=(abs(a)//abs(b))*(-1 if (a<0)^(b<0) else 1) if b else 0
            elif op=='%':v=a-(a//b)*b if b else 0
            else:v=1 if a>b else 0
            result=(v,ra|rb)
        elif op=='k':
            a,ra=solve(t-1,len(pre)-3);b,rb=solve(t-1,len(pre)-2)
            result=(a+b,ra|rb)
        else:
            raise ValueError('B_NUMERIC unexplained produced slot '+str(t))
        need(result[0]==post[slot], 'B_NUMERIC independently computed value mismatch at '+str(t))
        if op in '+-*/%`!k' and slot==len(post)-1:
            seen_steps[t]={'tick':t,'op':op,'pre_tail':pre[-3:],
                            'B_value':result[0], 'root_ticks':sorted(result[1])}
        return result

    sink_records=[]
    for p in witness['puts']:
        ip=tuple(p['ip'])
        if ip not in SECOND:continue
        t=p['tick']; e=rows[t-1];need(e['op']==ord('p'),'B_NUMERIC put identity')
        value,root_ticks=solve(t-1,len(e['pre'])-3)
        expected=sorted(r['tick'] for w in witness['puts'] if w['address']==p['address']
                        for r in w['g_reads'])
        need(value==p['value']==e['pre'][-3],'B_NUMERIC overwrite value mismatch')
        need(sorted(root_ticks)==expected,'B_NUMERIC g lineage mismatch: '+str(t))
        sink_records.append({'tick':t,'ip':p['ip'],'address':p['address'],'value':value,
                             'roots':sorted(root_ticks)})
    need(len(sink_records)==2,'B_NUMERIC two overwrites')
    return sink_records,list(seen_steps.values())


def audit_case(rows,witness,bj_rows):
    physical(rows)
    need(witness['steps']==len(rows) and witness['trace_sha256'] in bj_rows,'witness/case length')
    need(len(witness['puts'])==4 and len(witness['g_downstream'])==4,'witness shape')
    need({tuple(p['ip']) for p in witness['puts']}==set(FIRST)|set(SECOND),'p site identity')
    need({tuple(r['ip']) for p in witness['puts'] for r in p['g_reads']}==READ_IPS,'g site identity')
    need(len(bj_rows[witness['trace_sha256']])==2,'BJ matched two signed reads')
    a=oracle_a(rows,witness)
    b,steps=oracle_b(rows,witness)
    forward_by_tick={r['tick']:r for r in a['numeric_steps']}
    need(len(forward_by_tick)==a['checks']['arithmetic'], 'A_NUMERIC duplicate step ticks')
    for node in steps:
        corresponding=forward_by_tick.get(node['tick'])
        need(corresponding is not None and corresponding['op']==node['op'] and
             corresponding['A_value']==node['B_value'],
             'independent numeric A/B disagreement at '+str(node['tick']))
        node['A_value']=corresponding['A_value']
    later_ticks={p['tick'] for p in witness['puts'] if tuple(p['ip']) in SECOND}
    need({(t,addr,v) for t,addr,v in a['write_events'] if t in later_ticks}
         =={(p['tick'],tuple(p['address']),p['value']) for p in witness['puts'] if tuple(p['ip']) in SECOND},
         'A/B written value witness mismatch')
    b_by_t={r['tick']:r for r in b}
    for p in witness['puts']:
        if tuple(p['ip']) in SECOND:
            need(p['tick'] in b_by_t and p['value']==b_by_t[p['tick']]['value'],'A/B sink alignment')
    return {'case':witness['case'],'trace_sha256':witness['trace_sha256'],
            'steps':len(rows),'interval':[a['start'],a['end']],
            'numeric_steps_forward':a['checks']['arithmetic'],
            'mod_M_steps':a['checks'].get('mod_M',0),
            'numeric_steps_reverse':len(steps),'overwrites':b,
            'arithmetic_witnesses':sorted(steps,key=lambda r:r['tick'])}


def toy_checks():
    need(M==170141183460469231731687303715884105727,'MAX literal')
    need((-M+1)%M==1,'positive Euclidean residue')
    need((M+2)%M==2,'positive residue')
    need(truncate_zero(-(1<<127)+13,7)==-( ((1<<127)-13)//7 ),'large exact truncation')
    need(truncate_zero(-13,5)==-2 and truncate_zero(13,-5)==-2,'truncation toward zero')
    a={'t':1,'ip':[0,0],'post':[-1]}
    need(forward_op('-', [0,1],a)==[-1],'forward subtraction')
    need(forward_op('%', [-M+1,M],a)==[1],'forward explicit M modulus')
    try:
        need(forward_op('%', [-M+1,M],a)==[0],'negative self-check')
    except ValueError:pass
    else:raise ValueError('toy expected-red was green')
    return 7


def run(args):
    paths={'BI':args.bi,'BJ':args.bj,'BK':args.bk}
    for k,p in paths.items():need(digest(p.read_bytes())==PINS[k], 'SHA256 '+k)
    bi=[json.loads(s) for s in args.bi.read_text().splitlines()]
    bj=[json.loads(s) for s in args.bj.read_text().splitlines()]
    bk=[json.loads(s) for s in args.bk.read_text().splitlines()]
    signed={w['trace_sha256']:w for w in bk}
    bj_map=defaultdict(list)
    for e in bj:bj_map[e['trace_sha256']].append(e)
    need(len(bi)==225 and len(bj)==270 and len(bk)==135 and len(signed)==135,'pinned witness counts')
    need(set(signed)==set(bj_map),'pinned BK/BJ membership')
    ai=original_zip(args.ai.read_bytes(),'AI')
    ah=original_zip(ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'),'AH')
    y=original_zip(ah.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'),'Y')
    counts=Counter();evidence=[];cases=[];negative=[]
    original_trace_digest=set()
    for sn in range(8):
        shard=zipfile.ZipFile(io.BytesIO(y.read(f'QA31V_SHARD{sn}.zip')))
        need(shard.testzip() is None,'original shard CRC')
        receipt=json.loads(shard.read('qa31v_receipt.json'))
        need(receipt['source_blob']==SOURCE_BLOB and receipt['shard']==sn and len(receipt['cases'])==25,'original source/shard')
        for c in receipt['cases']:
            need(c['status']=='HALT' and c['error'] is None and c['steps']<=25000,'signed HALT/step limit')
            compressed=shard.read(c['trace']);chash=digest(compressed)
            need(chash==c['trace_sha256'] and chash not in original_trace_digest,'original receipt SHA/unique')
            original_trace_digest.add(chash)
            counts['original_cases']+=1;counts['original_steps']+=c['steps']
            if chash not in signed:continue
            rows=[json.loads(x) for x in gzip.decompress(compressed).splitlines()]
            need(len(rows)==c['steps'] and signed[chash]['case']==c['label'],'signed case correspondence')
            result=audit_case(rows,signed[chash],bj_map)
            evs=result.pop('arithmetic_witnesses')
            counts['selected_cases']+=1
            counts['g']+=sum(len(p['g_reads']) for p in signed[chash]['puts'])
            counts['overwrites']+=len(result['overwrites'])
            counts['numeric_steps_forward']+=result['numeric_steps_forward']
            counts['numeric_steps_reverse']+=result['numeric_steps_reverse']
            counts['mod_M_steps']+=result['mod_M_steps']
            evidence.extend({'case':result['case'],**e} for e in evs)
            cases.append(result)
            if not negative:
                candidates=[e['tick'] for e in evs if e['op'] in '+-*%' and e['tick']<len(rows)]
                need(len(candidates)>=12,'insufficient real arithmetic mutations')
                for tick in candidates[:12]:
                    forged=list(rows)
                    first=copy.deepcopy(rows[tick-1]);following=copy.deepcopy(rows[tick])
                    first['post'][-1]+=1
                    following['pre'][-1]+=1
                    forged[tick-1]=first;forged[tick]=following
                    # Physical links still pass; rejection must be numerical.
                    physical(forged)
                    try:oracle_a(forged,signed[chash])
                    except ValueError as exc:
                        need('A_NUMERIC' in str(exc),'non-numeric mutation rejection at '+str(tick)+': '+str(exc))
                        negative.append({'tick':tick,'op':chr(rows[tick-1]['op']),'reason':str(exc)})
                    else:raise ValueError('arithmetic original STEP mutation not detected '+str(tick))
    need((counts['original_cases'],counts['original_steps'],counts['selected_cases'])==(200,3628390,135),'original corpus totals')
    need((counts['g'],counts['overwrites'],len(negative))==(540,270,12),'g/overwrite/hostile totals')
    need(counts['mod_M_steps']>0,'observed signed modulo M missing')
    out=args.out;need(not out.exists(),'output directory already exists');out.mkdir(parents=True)
    case_bytes=b''.join(json.dumps(r,sort_keys=True,separators=(',',':')).encode()+b'\n' for r in sorted(cases,key=lambda r:r['case']))
    step_bytes=b''.join(json.dumps(r,sort_keys=True,separators=(',',':')).encode()+b'\n' for r in sorted(evidence,key=lambda r:(r['case'],r['tick'])))
    (out/'qa31bl_cases.jsonl').write_bytes(case_bytes)
    with gzip.GzipFile(str(out/'qa31bl_numeric_steps.jsonl.gz'),mode='wb',mtime=0) as f:f.write(step_bytes)
    summary={'project_id':PROJECT,'scope':'finite 135 original signed cases; no new Native; Stage1 OPEN',
             'source_blob':SOURCE_BLOB,'pins':PINS,'counts':dict(counts),'modulus':str(M),
             'modulo_semantics':'Python Euclidean remainder for positive divisor M; no global machine-int wrap',
             'oracles':['A forward complete concrete STEP replay','B independent reverse stack-slot expression'],
             'cases_sha256':digest(case_bytes),'numeric_steps_raw_sha256':digest(step_bytes),
             'mutation_count':len(negative),'mutations':negative,'toy_checks':toy_checks(),
             'new_native_runs':0,'stage1_pass':False,'counterfactual_causality_proven':False}
    (out/'qa31bl_summary.json').write_text(json.dumps(summary,indent=2,sort_keys=True,ensure_ascii=False)+'\n')
    print(json.dumps({k:summary[k] for k in ['counts','cases_sha256','numeric_steps_raw_sha256','mutation_count','toy_checks','stage1_pass']},sort_keys=True))


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--self-test',action='store_true')
    for x in ('ai','bi','bj','bk','out'):p.add_argument('--'+x,type=Path)
    args=p.parse_args()
    if args.self_test:print('toy checks:',toy_checks())
    else:
        need(all(getattr(args,x) is not None for x in ('ai','bi','bj','bk','out')),'--ai --bi --bj --bk --out required')
        run(args)
if __name__=='__main__':main()
