#!/usr/bin/env python3
"""QA31BR: independently check source-cell ownership and one-step geometry.

Works only on preexisting SHA-pinned original Native traces. Hypothetical opcode
geometry does NOT execute an altered program. Python 3.11+, stdlib only.
Requires qa31bp_original_output_ancestry.py in the same directory.
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

from qa31bp_original_output_ancestry import (
    PIN, P, SOURCE, check_manifest, demand, digest, original_cases, op
)

BP_SHA = 'd0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24'
BQ_SHA = '23a587a58970031d56290399aed0db6f2df55a4107e322f6baa777fb054f1620'
CELL = (1500,1860)
G_CELL = (19,1696)
# Read separately from GitHub's immutable Git blob 560d6a... on 2026-11-21.
# Coordinates are ZERO-based x (column), y (line). This is a local source
# excerpt, not a locally re-hashed full source file.
SOURCE_RIGHT = ' >01-.01-.01-.01-.01-.01-.01-.@' # x=1500..1530 at y=1860
SOURCE_COLUMN = ' v7a*9+1a*7+a*1+a*0+g'  # y=1860..1880 at x=1500


def read_cases(raw:bytes, kind:str, sha:str, entry:str, key:str)->dict:
    demand(digest(raw)==sha, kind+' input ZIP SHA mismatch')
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        demand(z.testzip() is None,kind+' ZIP CRC')
        check_manifest(z,'MANIFEST.json')
        rows=[json.loads(x) for x in z.read(entry).splitlines() if x.strip()]
        demand(len(rows)==135 and len({r[key] for r in rows})==135,kind+' case count')
        return {r[key]:r for r in rows}


def source_char(x:int,y:int)->str:
    if y==1860 and 1500<=x<1500+len(SOURCE_RIGHT):
        return SOURCE_RIGHT[x-1500]
    if x==1500 and 1860<=y<1860+len(SOURCE_COLUMN):
        return SOURCE_COLUMN[y-1860]
    raise ValueError('outside Git-blob-pinned excerpt; no source prediction')


def oracle_A_forward(events:list, source_at=source_char)->dict:
    """Chronological physical p owner map + direct original source lookups."""
    p_owner={}
    seen_g=None
    candidate=None
    for e in events:
        name=op(e)
        if name=='p':
            demand(len(e['pre'])>=3,'p missing operands')
            p_owner[tuple(e['pre'][-2:])]=(e['t'],e['pre'][-3])
        if tuple(e['ip'])==(677,765):
            demand(name=='g' and e['pre']==[19,1696] and e['post']==[0], 'signed g mismatch')
            seen_g=e['t']
        if tuple(e['ip'])==CELL:
            demand(candidate is None,'multiple target fetches')
            candidate=e
            owner=p_owner.get(CELL)
            demand(owner is not None and owner[1]==ord('>') and e['op']==owner[1],
                   'forward owner/fetch mismatch')
            demand(source_at(*CELL)==' ' and source_at(1501,1860)=='>'
                   and source_at(1500,1861)=='v' and source_at(1500,1862)=='7',
                   'source excerpt mismatch')
            demand(e['next']==[1501,1860] and e['next_delta']==[1,0],
                   'original physical next/delta')
            return {'owner_tick':owner[0], 'owner_value':owner[1],
                    'fetch_tick':e['t'],'g_tick':seen_g,'original_next':e['next'],
                    'right_source':source_at(1501,1860),
                    'down_source':source_at(1500,1861)}
    raise ValueError('missing executable code fetch')


def oracle_B_reverse(events:list, source_at=source_char)->dict:
    """Reverse search for last physical writer + vector computed geometry.

    Does not call A, reuse A's map, or rely on a derived BP/BQ owner. It checks
    the original next step against the trace and calculates BOTH conditional
    steps by displacement rather than reading next from A.
    """
    hit=[i for i,e in enumerate(events) if tuple(e['ip'])==CELL]
    demand(len(hit)==1,'physical fetch count')
    i=hit[0]; fetch=events[i]
    demand(op(fetch)=='>' and fetch['pre']==[] and fetch['post']==[],
           'physical original fetch state')
    demand(i+1<len(events) and tuple(events[i+1]['ip'])==(1501,1860)
           and op(events[i+1])=='>', 'signed next instruction')
    candidate=None
    for j in range(i-1,-1,-1):
        e=events[j]
        if op(e)=='p' and e['pre'][-2:]==[1500,1860]:
            candidate=e;break
    demand(candidate is not None and candidate['pre'][-3:]==[62,1500,1860]
           and candidate['t']<fetch['t'],'reverse last owner')
    g=[e for e in events[:i] if tuple(e['ip'])==(677,765)]
    demand(len(g)==1 and op(g[0])=='g' and g[0]['pre']==[19,1696]
           and g[0]['post']==[0] and g[0]['t']<candidate['t'],'reverse source g')
    # The source at the target is originally SPACE, so the observed > is
    # attributed to the actual p, not the static file.
    demand(source_at(1500,1860)==' ','source original target altered')
    alternatives={'>': (CELL[0]+1,CELL[1]), 'v': (CELL[0],CELL[1]+1)}
    demand(source_at(*alternatives['>'])=='>' and source_at(*alternatives['v'])=='v',
           'source successor geometry altered')
    demand(fetch['next']==list(alternatives['>']), 'original physical successor disagree')
    return {'owner_tick':candidate['t'],'owner_value':candidate['pre'][-3],
            'fetch_tick':fetch['t'],'g_tick':g[0]['t'],
            'successors':{k:[*coord] for k,coord in alternatives.items()},
            'right_source':source_at(*alternatives['>']),
            'down_source':source_at(*alternatives['v'])}


def signed_boundary(events:list, bp:dict, bq:dict)->dict:
    """Check exact original source/data-code boundary, never a changed run."""
    a=oracle_A_forward(events)
    b=oracle_B_reverse(events)
    for field in ('owner_tick','owner_value','fetch_tick','g_tick','right_source','down_source'):
        demand(a[field]==b[field],'two oracles disagree on '+field)
    p_tick=bp['last_p_after_g']['tick']
    demand(p_tick==a['owner_tick']==bq['original_p_tick']
           and a['fetch_tick']==bp['code_fetch_tick']==bq['original_code_fetch_tick']
           and a['g_tick']==bp['g_tick']==bq['original_g_tick'],
           'independent BP/BQ receipt cross-pin')
    demand(0<a['g_tick']<p_tick<a['fetch_tick']<len(events), 'physical tick ordering')
    demand(events[p_tick-1]['pre']==[62,1500,1860]
           and op(events[p_tick-1])=='p'
           and events[p_tick-1]['ip']==[96,480]
           and events[p_tick-1]['post']==[],'signed source cell write')
    demand(events[-1]['t']==len(events) and op(events[-1])=='@','signed HALT')
    # Formal, frozen-to-this-boundary byte hypotheses only. Not altered runs.
    possibilities=[]
    for g,expected in [(0,62),(1,118)]:
        v=56*g+62
        demand(v==expected,'BQ arithmetic hypothesis changed')
        opcode=chr(v)
        next_ip=b['successors'][opcode]
        possibilities.append({'g_hypothesis':g,'code_byte_if_writer_reached':v,
                              'opcode_if_fetched':opcode, 'one_step_next_if_fetched':next_ip,
                              'static_source_at_one_step_next':source_char(*next_ip),
                              'changed_run_actual_fetch_route_output':'UNKNOWN'})
    return {'case':bp['case'],'trace_sha256':bp['trace_sha256'],
            'g_tick':a['g_tick'],'original_writer_tick':p_tick,
            'original_fetch_tick':a['fetch_tick'],'source_initial_code_byte':32,
            'source_right':a['right_source'],'source_down':a['down_source'],
            'original_physical_next':a['original_next'],'hypotheses':possibilities,
            'altered_run_reachability':'UNKNOWN'}


def hostile_tests(events:list, bp:dict, bq:dict)->list[dict]:
    """Detached corruptions of one REAL original trace; not Native reruns."""
    p=bp['last_p_after_g']['tick'];f=bp['code_fetch_tick'];g=bp['g_tick']
    edits=[
        ('p_value',p,'pre',0,1),('p_x',p,'pre',1,1),('p_y',p,'pre',2,1),
        ('p_op',p,'op',None,ord('g')),('p_ip',p,'ip',0,1),
        ('p_post',p,'post',None,[9]),
        ('g_addr_x',g,'pre',0,1),('g_addr_y',g,'pre',1,1),
        ('g_return',g,'post',0,1),('g_op',g,'op',None,ord('p')),
        ('fetch_op',f,'op',None,ord('v')),('fetch_ip_x',f,'ip',0,1),
        ('fetch_ip_y',f,'ip',1,1),('fetch_next_x',f,'next',0,1),
        ('fetch_next_delta_x',f,'next_delta',0,1),
        ('fetch_pre',f,'pre',None,[0]),('fetch_post',f,'post',None,[0]),
        ('neighbor_op',f+1,'op',None,ord('v')),
    ]
    out=[]
    for name,t,field,idx,repl in edits:
        copy_events=list(events)
        copy_events[t-1]=copy.deepcopy(events[t-1])
        item=copy_events[t-1]
        if idx is None:item[field]=repl
        else:item[field][idx]+=repl
        try:
            signed_boundary(copy_events,bp,bq)
        except (AssertionError,ValueError,IndexError,KeyError,TypeError) as exc:
            out.append({'name':name,'rejected':True,'reason':str(exc)[:180]})
        else:
            raise ValueError('HOSTILE ACCEPTED: '+name)
    # Source excerpt corruption, separately from physical trace corruption.
    for name,point,wrong in [('source_right',(1501,1860),'?'),('source_down',(1500,1861),'?')]:
        def bad(x,y,point=point,wrong=wrong):
            return wrong if (x,y)==point else source_char(x,y)
        try:
            oracle_A_forward(events,bad)
            oracle_B_reverse(events,bad)
        except (AssertionError,ValueError) as exc:
            out.append({'name':name,'rejected':True,'reason':str(exc)[:180]})
        else:
            raise ValueError('SOURCE HOSTILE ACCEPTED: '+name)
    return out


def write_jsonl(path:Path,rows:list[dict]):
    path.write_text(''.join(json.dumps(x,ensure_ascii=False,sort_keys=True)+'\n' for x in rows),encoding='utf-8')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for flag in ('ai','bn','bo','bp','bq'):p.add_argument('--'+flag,required=True,type=Path)
    p.add_argument('--out',required=True,type=Path)
    args=p.parse_args()
    demand(not args.out.exists(),'do not overwrite existing results')
    data={k:getattr(args,k).read_bytes() for k in ('ai','bn','bo','bp','bq')}
    for k in ('ai','bn','bo'):demand(digest(data[k])==PIN[k.upper()],k+' SHA pin')
    prior_bp=read_cases(data['bp'],'BP',BP_SHA,'evidence/qa31bp_cases.jsonl','case')
    prior_bq=read_cases(data['bq'],'BQ',BQ_SHA,'evidence/qa31bq_cases.jsonl','case')
    rows=[]; noops=0; hostile=[]; signed=Counter()
    for case,events,source_controls,progress in original_cases(data['ai'],data['bn'],data['bo']):
        label=case['label'];demand(label in prior_bp and label in prior_bq,'missing prior case')
        bp=prior_bp[label]; bq=prior_bq[label]
        demand(bp['trace_sha256']==bq['signed_trace_sha256']==case['trace_sha256'],
               'source archive/case SHA identity')
        row=signed_boundary(events,bp,bq)
        demand(row['case']==label and row['original_physical_next']==[1501,1860],
               'original physical next not east')
        rows.append(row)
        for noop in source_controls:
            if noop['classification']!='NO_NUMERIC_EFFECT':continue
            demand(noop['case']==label and noop['trace_sha256']==case['trace_sha256']
                   and noop['intervention_g']==noop['original_g']
                   and noop['forward_sinks']==noop['baseline_sinks'],
                   'not genuine original no-effect control')
            demand(row['original_physical_next']==[1501,1860], 'no-op route discrepancy')
            noops+=1
        if not hostile:hostile=hostile_tests(events,bp,bq)
        signed=progress
    demand(len(rows)==135 and len(set(r['case'] for r in rows))==135,'case count')
    demand(noops>=12 and len(hostile)>=12 and all(x['rejected'] for x in hostile),
           'positive/negative control gate')
    demand(signed['original']==200 and signed['steps']==3628390, 'source corpus count')
    demand(len(prior_bp)==len(prior_bq)==len(rows),'prior cohort mismatch')
    summary={'project_id':P,'qa':'QA31BR','source_blob':SOURCE,
             'source_geometry_evidence':'GitHub immutable blob excerpt, checked against 135 signed original physical traces; full original source not rehashed locally',
             'source_original_at_1500_1860':'ASCII 32 SPACE',
             'original_actual_code':'>','conditional_g1_code_if_same_p':'v',
             'original_actual_one_step_next':[1501,1860],
             'conditional_g1_one_step_next_if_fetched':[1500,1861],
             'source_at_original_next':'>','source_at_conditional_next':'v',
             'signed_original_cases':signed['original'],'signed_original_steps':signed['steps'],
             'selected_original_traces_rechecked':len(rows),
             'independent_physical_owner_oracles':'chronological p-write map AND reverse scan from signed CODE_FETCH',
             'independent_geometry_oracles':'source excerpt coordinate lookup AND mathematical direction/physical-next trace check',
             'verified_genuine_noops':noops,'detached_hostile_mutations_rejected':len(hostile),
             'input_sha256':{k.upper():digest(v) for k,v in data.items()},
             'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False,
             'actual_modified_route_fetch_writer_output':'UNKNOWN'}
    args.out.mkdir(parents=True)
    write_jsonl(args.out/'qa31br_cases.jsonl',rows)
    write_jsonl(args.out/'qa31br_hostiles.jsonl',hostile)
    (args.out/'qa31br_summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps(summary,sort_keys=True,ensure_ascii=False))

if __name__=='__main__':main()