#!/usr/bin/env python3
"""QA31AA: bounded finite physical j185 operand root / Funge-space audit.

Original artifacts only. No Native executions, no claims of byte ownership.
Requires frozen same-branch QA31X, QA31Y, QA31Z QA modules and Python >=3.9.
"""
import argparse
import collections
import copy
import csv
import json
from pathlib import Path

from stage1_qa31x_pairwise_first_divergence import CaseReader, load_w_csv, selected_pairs, check
from stage1_qa31y_source_pinned_last_writer_reader import (
    OPCODES, SOURCE_BLOB, local_j_check, source_sites_check, p_address, g_address,
)
from stage1_qa31z_bounded_stack_dependency import Tag, UNKNOWN, op_transfer

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
BRANCH = 'qa-befunge98-stage1-order-isolation-20261008'
BASE_HEAD = '94c75f181c9f48e638821d57ebbb161dea255daf'
CAP = 768
J = (185,8)
EARLY_G = (57,8)
LATE_G = (151,8)
EARLY_P = (60,5)
FUNGE_CELL = (0,49)


def matching_indices(events, end, coord, opcode, lo):
    return [i for i in range(lo,end) if events[i]['op']==opcode and tuple(events[i]['ip'])==coord]


def last_physical_writer(events, before, address, lo):
    """Return last observed p writer in bounded window, not an unobserved owner."""
    matches=[i for i in range(lo,before) if events[i]['op']==112 and p_address(events[i])==address]
    return matches[-1] if matches else None


def audit_one(events, j_index, label):
    j=events[j_index]
    check(j['op']==106 and tuple(j['ip'])==J,'incorrect j site')
    flag=local_j_check(events,j_index)
    lo=max(0,j_index-CAP)
    earlier=matching_indices(events,j_index,EARLY_G,103,lo)
    later=matching_indices(events,j_index,LATE_G,103,lo)
    # Missing roots stay unknown; never declare a resolved root from a numeric match.
    result={'label':label,'j_tick':j['t'],'j_operand':j['pre'][-1],
      'j_flag':flag,'window_cap':CAP,'status':'unknown',
      'g57_tick':None,'g151_tick':None,'g57_value':None,
      'p60_tick':None,'p60_value':None,'g57_address':None,
      'root_sites':[],'unsupported_steps':[],'intervening_s':[],
      'p_to_g_value_match':None,'physical_stack_transfer_pass':False,
      'observed_fungespace_writer':False,
      'global_input_byte_owner':'unknown','stage1_pass':False}
    if not earlier or not later:return result
    k=earlier[-1];gidx=later[-1]
    if not k<gidx<j_index:return result
    g1=events[k];g2=events[gidx]
    result.update(g57_tick=g1['t'],g151_tick=g2['t'],g57_value=g1['post'][-1] if g1['post'] else None,
                  g57_address=list(g_address(g1)) if g_address(g1) else None)
    # Both source-pinned g sites are checked in source_sites_check; the new p site was pinned too.
    check(OPCODES[EARLY_G]==103 and OPCODES[LATE_G]==103 and OPCODES[EARLY_P]==112,'source pin missing')
    # Verify physical stack continuity from the new earliest root through target jump.
    tags=[UNKNOWN for _ in g1['pre']]
    origins=set()
    for i in range(k,j_index):
        e=events[i]
        if i>k:check(events[i-1]['post']==e['pre'],f'physical pre/post gap {label} tick={e["t"]}')
        # Target additional g(57,8) is intentionally included; tag others via original QA31Z rules.
        tags,ok,origin=op_transfer(e,tags)
        if not ok:result['unsupported_steps'].append(e['t'])
        if origin is not None:origins.add(origin)
    check(len(tags)==len(j['pre']),'j operand stack cardinality differs')
    root=tags[-1]
    actual={tuple(x) for x in root.sources}
    result['root_sites']=[list(x) for x in sorted(actual)]
    result['physical_stack_transfer_pass']=True
    # Source of g(57,8) is not necessarily input: examine observed p/s changes to target memory.
    address=g_address(g1)
    writer=last_physical_writer(events,k,address,lo) if address else None
    if writer is not None:
        p=events[writer]
        result.update(p60_tick=p['t'],p60_value=p['pre'][-3],
                      p_to_g_value_match=p['pre'][-3]==g1['post'][-1],
                      observed_fungespace_writer=True)
        result['intervening_s']=[e['t'] for e in events[writer+1:k] if e['op']==ord('s')]
    desired={(EARLY_G[0],EARLY_G[1],g1['t']),(LATE_G[0],LATE_G[1],g2['t'])}
    if (actual==desired and not root.opaque and not result['unsupported_steps']
         and address==FUNGE_CELL and writer is not None and tuple(events[writer]['ip'])==EARLY_P
         and result['p_to_g_value_match'] and not result['intervening_s']):
        result['status']='two_physically_observed_g_roots_with_value_matched_p'
    return result


def local_guards():
    # Checks against improper claims/modified evidence; not a new Native test.
    checks=0
    def ensure(x):
        nonlocal checks
        check(x,'QA31AA synthetic guard '+str(checks+1));checks+=1
    p={'op':112,'pre':[7,0,49],'ip':[60,5]}
    g={'op':103,'pre':[0,49],'post':[7],'ip':[57,8]}
    ensure(p_address(p)==FUNGE_CELL)
    ensure(g_address(g)==FUNGE_CELL)
    ensure(p['pre'][-3]==g['post'][-1])
    ensure(p_address({'pre':[7,0,48]})!=FUNGE_CELL)
    ensure(p['pre'][-3]!=8)
    ensure(OPCODES[EARLY_G]==103)
    ensure(OPCODES[LATE_G]==103)
    ensure(OPCODES[EARLY_P]==112)
    # A rooted numeric zero alone is not proof of absence of structural dependence.
    ensure(Tag(frozenset({(57,8,1)})).sources==frozenset({(57,8,1)}))
    ensure(UNKNOWN.opaque and not UNKNOWN.sources)
    ensure(CAP==768)
    return checks


def run(zip_dir,qa31w,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    rows=load_w_csv(qa31w);pairs,_=selected_pairs(rows)
    labels=sorted({x['label'] for _,a,b in pairs for x in (a,b)})
    check(len(labels)==29,'selection changed')
    lookup={r['label']:r for r in rows}
    reader=CaseReader(zip_dir)
    from stage1_qa31z_bounded_stack_dependency import G_SITES
    before=set(G_SITES);G_SITES.add(EARLY_G)
    witnesses=[];source_checks=0
    try:
        for label in labels:
            events=reader.load(lookup[label]);source_checks+=source_sites_check(events)
            for index,e in enumerate(events):
                if tuple(e['ip'])==J and e['op']==106:
                    witnesses.append(audit_one(events,index,label))
    finally:
        G_SITES.clear();G_SITES.update(before)
    check(len(witnesses)==261,'expected QA31Z unresolved j185 records')
    check(source_checks==3557,'source-pinned site count drift')
    guard_count=local_guards()
    counts=collections.Counter(w['status'] for w in witnesses)
    values=collections.Counter(w['g57_value'] for w in witnesses)
    distances=collections.Counter((w['j_tick']-w['g57_tick'] if w['g57_tick'] else None,
                    w['g151_tick']-w['g57_tick'] if w['g151_tick'] and w['g57_tick'] else None,
                    w['g57_tick']-w['p60_tick'] if w['p60_tick'] else None) for w in witnesses)
    summary={'schema':'qa31aa-finite-original-j185-stack-two-g-roots-v1',
       'project_id':PROJECT,'branch':BRANCH,'previous_head':BASE_HEAD,'source_blob':SOURCE_BLOB,
       'original_native_run':41689861481,'lookback_cap':CAP,
       'original_zip_sha256_crc_checked':len(reader.zips),
       'original_signed_traces_verified':len(reader.processed),
       'signed_physical_steps_verified':sum(reader.processed.values()),
       'original_source_opcode_event_checks':source_checks,
       'j185_events':len(witnesses),'status_counts':dict(counts),
       'g57_value_histogram':{str(k):v for k,v in sorted(values.items())},
       'j_to_g57_g151_to_g57_g57_to_p60_distances':{'/'.join(str(n) for n in k):v for k,v in distances.items()},
       'local_synthetic_checks':guard_count,'new_native_runs':0,'stage1_pass':False,
       'input_byte_owner':'unknown','global_reachability_proven':False,
       'full_functional_qa_pass':False,'geometric_spaghetti_qa_pass':False}
    (out/'QA31AA_SUMMARY.json').write_text(json.dumps(summary,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    (out/'QA31AA_WITNESSES.json').write_text(json.dumps(witnesses,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    with (out/'QA31AA_WITNESSES.csv').open('w',encoding='utf-8',newline='') as f:
        w=csv.writer(f);w.writerow(['label','j_tick','j_operand','status','g57_tick','g151_tick','p60_tick',
                           'g57_value','p60_value','address','root_sites','physical_transfer','byte_owner'])
        for x in witnesses:
            w.writerow([x['label'],x['j_tick'],x['j_operand'],x['status'],x['g57_tick'],x['g151_tick'],
                x['p60_tick'],x['g57_value'],x['p60_value'],x['g57_address'],x['root_sites'],
                x['physical_stack_transfer_pass'],'unknown'])
    print(json.dumps(summary,sort_keys=True))
    return summary

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--zip-dir',required=True);parser.add_argument('--qa31w-csv',required=True)
    parser.add_argument('--out',required=True)
    a=parser.parse_args();run(a.zip_dir,a.qa31w_csv,a.out)
