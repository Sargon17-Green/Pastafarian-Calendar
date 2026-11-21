#!/usr/bin/env python3
"""QA31BT: signed ORIGINAL downstream FungeSpace owner/visit audit, never altered Native.

Requires six immutable QA31AI/BN/BO/BP/BQ/BR archive files and the pre-existing
QA31BP original corpus loader. Python 3.11+ standard library only.

Two deliberately independent ownership algorithms are used: chronological
last-write index and address-specific backward trace search. No modified
Befunge code is executed or inferred reachable.
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

SHA = {
    'BP':'d0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24',
    'BQ':'23a587a58970031d56290399aed0db6f2df55a4107e322f6baa777fb054f1620',
    'BR':'9ba864d36321d4c3063713d6be5ef4dd2603c257f06f977b43e4a736b56dfad9',
}
START_Y, END_Y = 1863, 1880
CELLS = tuple((1500,y) for y in range(START_Y, END_Y+1))
# 2026-11-21 independent direct read of Git object SHA1 560d6aa...,
# x=1500, original row numbers 1860..1880 (zero-based).
# The full 1.8-MB Git blob was not locally reproduced/rehash-verified.
PIN_COLUMN = ' v7a*9+1a*7+a*1+a*0+g'
PIN_ASCII_HEX = '20 76 37 61 2a 39 2b 31 61 2a 37 2b 61 2a 31 2b 61 2a 30 2b 67'


def source_cell(x: int, y: int) -> int:
    demand(x == 1500 and 1860 <= y <= 1880, 'outside immutable original source cell window')
    demand(bytes.fromhex(PIN_ASCII_HEX) == PIN_COLUMN.encode('ascii'), 'original Git blob excerpt corruption')
    return bytes.fromhex(PIN_ASCII_HEX)[y-1860]


def pinned_cases(data: bytes, name: str, entry: str):
    demand(digest(data) == SHA[name], name+' immutable ZIP SHA256')
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        demand(z.testzip() is None, name+' ZIP CRC')
        m=check_manifest(z, 'MANIFEST.json')
        demand(m['project_id']==P, name+' PROJECT_ID')
        rows=[json.loads(s) for s in z.read(entry).splitlines() if s.strip()]
        demand(len(rows)==135 and len({r['case'] for r in rows})==135, name+' unique cohort')
        return {r['case']:r for r in rows}


def operands(event):
    """Original Befunge p pops y, x, value; zero underflow is legal."""
    a=event['pre']
    return ([0]*max(3-len(a),0)+a)[-3:]


def fetch(events, receipt):
    tick=receipt['original_fetch_tick']
    w=receipt['original_writer_tick']
    demand(isinstance(tick,int) and isinstance(w,int) and 1<w<tick<len(events), 'fetch/writer bounds')
    e=events[tick-1]
    p=events[w-1]
    demand(e['t']==tick and e['ip']==[1500,1860] and op(e)=='>' and e['pre']==[] and e['post']==[]
        and e['next']==[1501,1860] and e['next_delta']==[1,0], 'signed original fetch anchor')
    demand(events[tick]['ip']==[1501,1860] and op(events[tick])=='>', 'signed original next opcode')
    demand(p['ip']==[96,480] and op(p)=='p' and operands(p)==[62,1500,1860] and p['post']==[],
        'signed original writer anchor')
    return tick


def forward(events, tick):
    """Oracle F: single chronological map of physical original p owner updates."""
    last={a:None for a in CELLS}
    count=Counter()
    for e in events[:tick-1]:
        if op(e) != 'p': continue
        pre=e['pre']; demand(e['post']==(pre[:-3] if len(pre)>=3 else []), 'p post-stack original')
        v,x,y=operands(e)
        a=(x,y)
        if a in last:
            last[a]=(e['t'],v)
            count[a]+=1
    return last,count


def backward(events,tick):
    """Oracle R: for each address independently search physical p instructions backward."""
    last={}; counts={}
    prefix=events[:tick-1]
    for a in CELLS:
        n=0; most_recent=None
        for e in reversed(prefix):
            if e['op'] != 112 or e['string'] is not False: continue
            v,x,y=operands(e)
            if x == a[0] and y == a[1]:
                demand(e['post']==(e['pre'][:-3] if len(e['pre'])>=3 else []), 'reverse p stack')
                n+=1
                if most_recent is None: most_recent=(e['t'],v)
        last[a]=most_recent
        counts[a]=n
    return last,counts


def audit(case, events, receipt, source_at=source_cell):
    demand(receipt['case']==case['label'] and receipt['trace_sha256']==case['trace_sha256'],
        'pinned BR trace association')
    f=fetch(events,receipt)
    F,fc=forward(events,f)
    R,rc=backward(events,f)
    demand(F==R and all(fc[a]==rc[a] for a in CELLS), 'forward/reverse p owner mismatch')
    # A separate entire-original-trace pass: IP visits (NOT just fetch prefix).
    visits=Counter(tuple(e['ip']) for e in events if tuple(e['ip']) in CELLS)
    rows=[]
    for x,y in CELLS:
        b=source_at(x,y)
        demand(b==PIN_COLUMN.encode('ascii')[y-1860], 'immutable original-source excerpt mismatch')
        own=F[(x,y)]
        rows.append({'cell':[x,y],'initial_ascii':b,'source_char':chr(b),
                     'original_pre_fetch_p_count':fc[(x,y)],
                     'original_last_p_tick':own[0] if own else None,
                     'original_last_p_value':own[1] if own else None,
                     'original_memory_at_original_fetch':own[1] if own else b,
                     'original_physical_ip_visits_total':visits[(x,y)]})
    return {'case':case['label'], 'trace_sha256':case['trace_sha256'],
            'original_fetch_tick':f,'cells':rows,
            'altered_run_writer_address_route_stack_output':'UNKNOWN'}


def hostile_controls(case, events, receipt, baseline):
    """Detached tampering: observed corpus remains immutable. No simulated Native.

    Rejection is a baseline mismatch, not a claim of a changed-run result.
    Original signed cases provide baseline, and the pinned source bytes form
    an independent static byte guard. Exactly 54 independent hostile probes.
    """
    output=[]
    pidx=next(i for i,e in enumerate(events[:receipt['original_fetch_tick']-1])
              if op(e)=='p' and len(e['pre'])>=3 and e['post']==e['pre'][:-3])
    ipidx=next(i for i,e in enumerate(events) if tuple(e['ip']) not in CELLS and i not in
               (pidx,receipt['original_fetch_tick']-1,receipt['original_writer_tick']-1))
    for idx,(x,y) in enumerate(CELLS):
        # Physical original p operand mutation: must not silently become a signed baseline.
        es=list(events);es[pidx]=copy.deepcopy(events[pidx]);es[pidx]['pre'][-2:]=[x,y]
        try:
            got=audit(case,es,receipt)
            rejected=(got != baseline)
        except (ValueError,AssertionError,KeyError,IndexError,TypeError): rejected=True
        demand(rejected,'hostile p mutation accepted at '+str((x,y)))
        output.append({'kind':'detached_p_address', 'cell':[x,y], 'rejected':True})
        # Physical IP visit mutation: a forged visit should be detected as changed evidence.
        es=list(events);es[ipidx]=copy.deepcopy(events[ipidx]);es[ipidx]['ip']=[x,y]
        try:
            got=audit(case,es,receipt)
            rejected=(got != baseline)
        except (ValueError,AssertionError,KeyError,IndexError,TypeError): rejected=True
        demand(rejected,'hostile IP visit accepted at '+str((x,y)))
        output.append({'kind':'detached_ip_visit', 'cell':[x,y], 'rejected':True})
        # Separate source oracle tamper: corrupt a single source character; audit rejects.
        def corrupt(px,py,tx=x,ty=y):
            z=source_cell(px,py)
            return (z+1)%128 if (px,py)==(tx,ty) else z
        try:
            audit(case,events,receipt,source_at=corrupt)
        except (ValueError,AssertionError,KeyError,IndexError,TypeError): rejected=True
        else: rejected=False
        demand(rejected,'hostile source byte accepted at '+str((x,y)))
        output.append({'kind':'detached_source_byte', 'cell':[x,y], 'rejected':True})
    return output


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for key in ('ai','bn','bo','bp','bq','br'): parser.add_argument('--'+key,type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    demand(not args.out.exists(),'output already exists; preserve prior evidence')
    data={key:getattr(args,key).read_bytes() for key in ('ai','bn','bo','bp','bq','br')}
    for key in ('ai','bn','bo'): demand(digest(data[key])==PIN[key.upper()],key+' SHA')
    bp=pinned_cases(data['bp'],'BP','evidence/qa31bp_cases.jsonl')
    bq=pinned_cases(data['bq'],'BQ','evidence/qa31bq_cases.jsonl')
    br=pinned_cases(data['br'],'BR','evidence/qa31br_cases.jsonl')
    outputs=[]; hostile=[]; originals=Counter(); controls=0; count=Counter()
    for case,events,noops,progress in original_cases(data['ai'],data['bn'],data['bo']):
        label=case['label']
        demand(label in bp and label in bq and label in br, 'cohort membership')
        demand(bp[label]['trace_sha256']==br[label]['trace_sha256']==bq[label]['signed_trace_sha256']==case['trace_sha256'],
            'signed case SHA four-way pin')
        outcome=audit(case,events,br[label]);outputs.append(outcome)
        for row in outcome['cells']:
            y=row['cell'][1]
            count['writers_'+str(y)]+=row['original_pre_fetch_p_count']
            count['visits_'+str(y)]+=row['original_physical_ip_visits_total']
        for n in noops:
            if n['classification']!='NO_NUMERIC_EFFECT': continue
            demand(n['case']==label and n['trace_sha256']==case['trace_sha256']
                   and n['original_g']==n['intervention_g']
                   and n['baseline_sinks']==n['forward_sinks'], 'genuine unchanged/no-effect control')
            controls+=1
        if not hostile:
            hostile=hostile_controls(case,events,br[label],outcome)
        originals=progress
    demand(len(outputs)==135 and len({r['case'] for r in outputs})==135, 'selected original cohort')
    demand(originals['original']==200 and originals['steps']==3628390,'original receipts/physical STEP count')
    demand(controls>=12 and len(hostile)>=12 and all(x['rejected'] for x in hostile), 'control threshold')
    overview={
        'project_id':P, 'qa':'QA31BT', 'stage1_pass':False,
        'entry_head':'a86180b2834853df0875f3df309f40bb72a778c2',
        'original_source_git_blob':SOURCE,'source_excerpt_provenance':'GitHub immutable blob read x1500,y1860..1880; full blob not locally rehashed',
        'source_column_1860_1880':PIN_COLUMN,
        'audited_cells_count':len(CELLS), 'audited_cell_y_range':[START_Y,END_Y],
        'original_signed_halt_receipts':originals['original'], 'original_physical_steps':originals['steps'],
        'selected_complete_original_traces':len(outputs),
        'independent_forward_reverse_agreements':len(outputs)*len(CELLS),
        'per_cell_original_pre_fetch_p_writes':{str(y):count['writers_'+str(y)] for x,y in CELLS},
        'per_cell_original_ip_visits':{str(y):count['visits_'+str(y)] for x,y in CELLS},
        'genuine_unchanged_no_effect_controls':controls,
        'detached_hostile_rejections':len(hostile),
        'altered_run_reachability_route_writer_address_stack_native_output':'UNKNOWN',
        'new_native_runs':0,'new_ci_runs':0,
        'input_archives_sha256':{k.upper():digest(v) for k,v in data.items()}
    }
    args.out.mkdir(parents=True)
    for name,rows in [('qa31bt_cases.jsonl',outputs),('qa31bt_hostiles.jsonl',hostile)]:
        (args.out/name).write_text(''.join(json.dumps(v,ensure_ascii=False,sort_keys=True)+'\n' for v in rows),encoding='utf-8')
    (args.out/'qa31bt_summary.json').write_text(json.dumps(overview,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(overview,ensure_ascii=False,sort_keys=True))

if __name__=='__main__': main()