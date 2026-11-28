#!/usr/bin/env python3
"""QA31BS: original signed physical owner audit for conditional downward code corridor.

The program NEVER executes a modified Befunge program, nor estimates its output.
It checks historical original Native traces only. Python >=3.11, stdlib only.
Requires qa31bp_original_output_ancestry.py from frozen QA31BP in same directory.
"""
from __future__ import annotations
import argparse
from collections import Counter
import copy
import hashlib
import io
import json
from pathlib import Path
import zipfile
from qa31bp_original_output_ancestry import P, PIN, SOURCE, check_manifest, demand, digest, original_cases, op

BP_SHA='d0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24'
BQ_SHA='23a587a58970031d56290399aed0db6f2df55a4107e322f6baa777fb054f1620'
BR_SHA='9ba864d36321d4c3063713d6be5ef4dd2603c257f06f977b43e4a736b56dfad9'
BASE=(1500,1860)
CELLS=((1500,1861),(1500,1862))
# This excerpt is sourced from original Git blob SOURCE; it is NOT a local
# SHA1 verification of the full 1.8 MB original source file.
COLUMN=' v7a*9+1a*7+a*1+a*0+g'
RIGHT=' >01-.01-.01-.01-.01-.01-.01-.@'

def excerpt(x:int,y:int)->str:
    if x==1500 and 1860<=y<1860+len(COLUMN):return COLUMN[y-1860]
    if y==1860 and 1500<=x<1500+len(RIGHT):return RIGHT[x-1500]
    raise ValueError('coordinate outside immutable source excerpt')

def prior_cases(data:bytes, sha:str, entry:str, field:str):
    demand(digest(data)==sha,'prior ZIP SHA mismatch '+entry)
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        demand(z.testzip() is None,'prior ZIP CRC '+entry)
        check_manifest(z,'MANIFEST.json')
        rows=[json.loads(s) for s in z.read(entry).splitlines() if s.strip()]
        demand(len(rows)==135 and len({r[field] for r in rows})==135, 'prior cohort '+entry)
        return {r[field]:r for r in rows}

def target_event(events,receipt):
    """Signed original fetch anchor; independent of either corridor owner scan."""
    f=receipt['original_fetch_tick']
    demand(isinstance(f,int) and 2<=f<len(events)-1,'bad signed fetch tick')
    e=events[f-1]
    demand(e['t']==f and e['ip']==[1500,1860] and op(e)=='>', 'original fetch anchor')
    demand(e['pre']==[] and e['post']==[] and e['next']==[1501,1860]
           and e['next_delta']==[1,0], 'signed fetch transition')
    demand(events[f]['ip']==[1501,1860] and op(events[f])=='>', 'original next physical opcode')
    p=receipt['original_writer_tick']
    demand(p<f and events[p-1]['ip']==[96,480] and op(events[p-1])=='p'
           and events[p-1]['pre'][-3:]==[62,1500,1860]
           and events[p-1]['post']==[], 'original writer anchor')
    return f

def p_operands(e):
    # Befunge stack underflow for p supplies zeroes, not malformed syntax.
    values=e['pre']
    return ([0]*max(0,3-len(values)) + values)[-3:]

def forward_owners(events,fetch_tick):
    """A: single physical chronological map, filtered to the two target coordinates."""
    state={coord:None for coord in CELLS}
    all_hits={coord:0 for coord in CELLS}
    for e in events[:fetch_tick-1]:
        if op(e)!='p':continue
        demand(e['post']==(e['pre'][:-3] if len(e['pre'])>=3 else []),'p consume operands')
        v,x,y=p_operands(e)
        coord=(x,y)
        if coord in state:
            state[coord]=(e['t'],v)
            all_hits[coord]+=1
    return state,all_hits

def reverse_owners(events,fetch_tick):
    """B: independent backward event walk per coordinate; no forward map use."""
    found={};count={}
    for coord in CELLS:
        latest=None; n=0
        for e in reversed(events[:fetch_tick-1]):
            if op(e)=='p' and tuple(p_operands(e)[-2:])==coord:
                demand(e['post']==(e['pre'][:-3] if len(e['pre'])>=3 else []), 'reverse p post stack')
                if latest is None:latest=(e['t'],p_operands(e)[0])
                n+=1
        found[coord]=latest;count[coord]=n
    return found,count

def audit_case(case,events,br):
    demand(br['case']==case['label'] and br['trace_sha256']==case['trace_sha256'], 'BR case trace SHA pin')
    f=target_event(events,br)
    a,ac=forward_owners(events,f)
    b,bc=reverse_owners(events,f)
    demand(a==b and ac==bc,'forward/reverse last physical p owners mismatch')
    # Asymmetrically compare each signed owner against exact original source:
    # when no p was recorded, initial bytes remain source chars at ORIGINAL fetch.
    result=[]
    for x,y in CELLS:
        owner=a[(x,y)]
        static=excerpt(x,y)
        result.append({'cell':[x,y],'source_char':static,'source_ascii':ord(static),
                       'original_pre_fetch_writes':ac[(x,y)],
                       'last_physical_p':None if owner is None else {'tick':owner[0],'ascii':owner[1]},
                       'original_byte_at_fetch':ord(static) if owner is None else owner[1],
                       'provenance':'ORIGINAL_SOURCE' if owner is None else 'OBSERVED_ORIGINAL_P'})
    demand(result[0]['source_char']=='v' and result[1]['source_char']=='7', 'frozen source geometry inconsistent')
    demand(excerpt(1500,1860)==' ' and excerpt(1501,1860)=='>', 'source orientation')
    return {'case':case['label'],'trace_sha256':case['trace_sha256'],
            'original_fetch_tick':f,'downward_cells':result,
            'conditional_hypothesis':'if g=1 AND same writer,address,fetch AND no further writes',
            'hypothetical_first_code':'v','hypothetical_one_step_next':[1500,1861],
            'static_downward_source':COLUMN[1:],
            'original_ip_visits_downward_cells':{str(coord):sum(tuple(e['ip'])==coord for e in events) for coord in CELLS},
            'modified_execution_reachability_writer_address_ip_opcode_output':'UNKNOWN'}

def hostiles(case,events,receipt):
    """Detached corruptions on an actual signed original, never simulated Native.

    These are source/receipt/trace tamper detections, not altered-run effects.
    """
    f=receipt['original_fetch_tick'];p=receipt['original_writer_tick']
    variants=[
        ('writer_y_to_down1',p,'pre',2,1),
        ('writer_y_to_down2',p,'pre',2,2),
        ('writer_x_changed',p,'pre',1,1),
        ('writer_value',p,'pre',0,1),
        ('writer_ip',p,'ip',0,1),
        ('writer_op',p,'op',None,ord('g')),
        ('writer_post',p,'post',None,[1]),
        ('fetch_ip_y',f,'ip',1,1),
        ('fetch_ip_x',f,'ip',0,1),
        ('fetch_op',f,'op',None,ord('v')),
        ('fetch_next_y',f,'next',1,1),
        ('fetch_next_x',f,'next',0,1),
        ('fetch_delta_x',f,'next_delta',0,1),
        ('fetch_pre',f,'pre',None,[1]),
        ('fetch_post',f,'post',None,[1]),
        ('next_ip_y',f+1,'ip',1,1),
        ('next_opcode',f+1,'op',None,ord('v')),
    ]
    rejected=[]
    for name,t,field,index,repl in variants:
        detached=list(events);detached[t-1]=copy.deepcopy(events[t-1]);target=detached[t-1]
        if index is None:target[field]=repl
        else:target[field][index]+=repl
        try:audit_case(case,detached,receipt)
        except (ValueError,AssertionError,IndexError,KeyError,TypeError) as exc:
            rejected.append({'name':name,'rejected':True,'reason':str(exc)[:180]})
        else:raise ValueError('HOSTILE ACCEPTED '+name)
    original_column=globals()['COLUMN']
    for name,changed in [('source_first_down',COLUMN[:1]+'?'+COLUMN[2:]),
                         ('source_second_down',COLUMN[:2]+'?'+COLUMN[3:])]:
        # Actually run the auditor with the corrupted source excerpt; restore
        # the original even if the audit throws. Do not alter source or Native.
        try:
            globals()['COLUMN']=changed
            audit_case(case,events,receipt)
        except (ValueError,AssertionError,IndexError,KeyError,TypeError) as exc:
            rejected.append({'name':name,'rejected':True,'reason':str(exc)[:180]})
        else:
            raise ValueError('SOURCE HOSTILE ACCEPTED '+name)
        finally:
            globals()['COLUMN']=original_column
    return rejected

def write_jsonl(path,rows):
    path.write_text(''.join(json.dumps(r,sort_keys=True,ensure_ascii=False)+'\n' for r in rows),encoding='utf-8')

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for flag in ('ai','bn','bo','bp','bq','br'):ap.add_argument('--'+flag,required=True,type=Path)
    ap.add_argument('--out',required=True,type=Path)
    args=ap.parse_args()
    demand(not args.out.exists(),'output exists; do not overwrite evidence')
    data={k:getattr(args,k).read_bytes() for k in ('ai','bn','bo','bp','bq','br')}
    for k in ('ai','bn','bo'):demand(digest(data[k])==PIN[k.upper()], k+' SHA mismatch')
    bp=prior_cases(data['bp'],BP_SHA,'evidence/qa31bp_cases.jsonl','case')
    bq=prior_cases(data['bq'],BQ_SHA,'evidence/qa31bq_cases.jsonl','case')
    br=prior_cases(data['br'],BR_SHA,'evidence/qa31br_cases.jsonl','case')
    rows=[];real_noops=0;hostile=[];signed=Counter();counter=Counter()
    for case,events,controls,progress in original_cases(data['ai'],data['bn'],data['bo']):
        label=case['label']
        demand(label in bp and label in bq and label in br, 'missing previous case')
        demand(br[label]['trace_sha256']==bp[label]['trace_sha256']==bq[label]['signed_trace_sha256']==case['trace_sha256'], 'four-way trace hash mismatch')
        row=audit_case(case,events,br[label])
        rows.append(row)
        for coord,visits in row['original_ip_visits_downward_cells'].items():
            counter['ip_visits_'+coord]+=visits
        for cell in row['downward_cells']:
            counter['p_hits_at_'+str(cell['cell'])]+=cell['original_pre_fetch_writes']
            counter['static_at_'+str(cell['cell'])]+=int(cell['provenance']=='ORIGINAL_SOURCE')
        for noop in controls:
            if noop['classification']!='NO_NUMERIC_EFFECT':continue
            demand(noop['case']==label and noop['trace_sha256']==case['trace_sha256']
                   and noop['intervention_g']==noop['original_g']
                   and noop['forward_sinks']==noop['baseline_sinks'], 'not genuine no-op')
            real_noops+=1
        if not hostile: hostile=hostiles(case,events,br[label])
        signed=progress
    demand(len(rows)==len(br)==len(bp)==len(bq)==135, 'cohort count')
    demand(len({r['case'] for r in rows})==135,'cohort unique')
    demand(signed['original']==200 and signed['steps']==3628390,'original signed corpus count')
    demand(real_noops>=12 and len(hostile)>=12 and all(x['rejected'] for x in hostile),'controls missing')
    summary={'project_id':P,'qa':'QA31BS','baseline_head':'468e3c8b1cbcd33025369980dd68a3226ff3cfbd',
             'source_blob':SOURCE,'source_excerpt':'column at x=1500,y=1860 onward; not complete rehash of Git source',
             'selected_original_cases':len(rows),'original_native_receipts':signed['original'],
             'signed_original_steps':signed['steps'],'forward_reverse_owners_agree':len(rows),
             'before_fetch_writes_per_cell':{str(c):counter['p_hits_at_'+str(list(c))] for c in CELLS},
             'static_source_owners_per_cell':{str(c):counter['static_at_'+str(list(c))] for c in CELLS},
             'physical_ip_visits_downward_cells':{str(c):counter['ip_visits_'+str(c)] for c in CELLS},
             'genuine_no_effect_controls':real_noops,'detached_hostile_rejected':len(hostile),
             'conditional_static_corridor':COLUMN[1:],'conditional_changed_run_status':'UNKNOWN',
             'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False,
             'inputs_sha256':{k.upper():digest(v) for k,v in data.items()}}
    args.out.mkdir(parents=True)
    write_jsonl(args.out/'qa31bs_cases.jsonl',rows)
    write_jsonl(args.out/'qa31bs_hostiles.jsonl',hostile)
    (args.out/'qa31bs_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,sort_keys=True))

if __name__=='__main__':main()