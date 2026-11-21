#!/usr/bin/env python3
"""QA31AA independent reverse structural oracle for signed original STEPs.

Separate reverse-index algorithm from QA31AA's forward Tag transfer. It
reopens eight SHA-pinned ZIPs and directly compares every emitted witness.
Unknown for any unsupported opcode, incomplete ancestry or claimed byte owner.
"""
import argparse
import collections
import copy
import json
from pathlib import Path
from stage1_qa31x_pairwise_first_divergence import CaseReader, load_w_csv, selected_pairs, check

CAP=768
J=(185,8)
G={(57,8),(151,8)}
P=(60,5)
CELL=(0,49)


def back(e,required):
    """Map demanded *post* stack indexes backward through one opcode.
    Returns (demanded pre indexes, newly traced roots, opaque) without
    calling the forward executor or using its Tag implementation.
    """
    pre=e['pre'];post=e['post'];n=len(pre);m=len(post)
    op=chr(e['op']) if 32<=e['op']<127 else '?'
    src=set();before=set();opaque=False
    arity=None
    if op in '0123456789abcdef' or op in '~&':arity=(0,1)
    elif op in '+-*/%`':arity=(2,1)
    elif op in '!g':arity=(1,1) if op=='!' else (2,1)
    elif op in 'p':arity=(3,0)
    elif op in '_|j$':arity=(1,0)
    elif op==':':arity=(1,2)
    elif op=='\\':arity=(2,2)
    elif op in ' ><^v#[]wrqz':arity=(0,0)
    else:return set(),set(),True
    pop,push=arity;cut=max(0,n-pop);expected=cut+push
    if expected!=m:return set(),set(),True
    if pop==0 and push==0 and pre!=post:return set(),set(),True
    for x in required:
        check(0<=x<m,'needed index beyond post')
        if x<cut:
            before.add(x);continue
        if op=='g':
            coord=tuple(e['ip'])
            if coord in G:src.add((*coord,e['t']))
            else:opaque=True
        elif op in '~&':opaque=True
        elif op in '0123456789abcdef':pass
        elif op in '!+-*/%`':before.update(range(max(0,n-pop),n))
        elif op==':':before.update(range(max(0,n-1),n))
        elif op=='\\':
            # With >=2 values, swap top two. With one, the missing value is 0.
            old=list(range(max(0,n-2),n))
            if len(old)==2:before.add(old[1] if x==cut else old[0])
            elif len(old)==1:
                if x==cut:before.add(old[0])
            # Underflow source is constant zero.
        else:return set(),set(),True
    return before,src,opaque


def physical_analysis(events,j_index):
    j=events[j_index]
    check(tuple(j['ip'])==J and j['op']==106 and j['pre'],'not j185')
    lo=max(0,j_index-CAP)
    needed={len(j['pre'])-1};roots=set();opaque=False
    for i in range(j_index-1,lo-1,-1):
        if not needed:break
        curr=events[i]
        if i+1<=j_index:
            check(curr['post']==events[i+1]['pre'],'physical stack discontinuity')
        needed,new_roots,bad=back(curr,needed)
        roots.update(new_roots)
        if bad:opaque=True;break
    if needed:opaque=True
    return roots,opaque


def independently_last_written(events,before,addr,lo):
    found=None
    for i in range(lo,before):
        e=events[i]
        if e['op']!=112 or len(e['pre'])<3:continue
        if tuple(e['pre'][-2:])==addr:found=i
    return found


def compare(w,events,j_idx):
    j=events[j_idx]
    check(w['label'] and w['j_tick']==j['t'],'wrong identity/tick')
    check(w['j_operand']==j['pre'][-1] and j['op']==106 and tuple(j['ip'])==J,'wrong j operand')
    check(j['pre'][-1]==61*w['j_flag'] and w['j_flag'] in (0,1),'wrong flag')
    check(w['window_cap']==CAP and w['global_input_byte_owner']=='unknown' and w['stage1_pass'] is False,
          'false global reachability/byte causality/pass')
    roots,opaque=physical_analysis(events,j_idx)
    check(not opaque,'unexpected opaque reverse lineage')
    check({tuple(s) for s in w['root_sites']}==roots,'reverse roots differ')
    check(len(roots)==2 and {tuple(x[:2]) for x in roots}==G,'not precisely two roots')
    t57=next(x[2] for x in roots if tuple(x[:2])==(57,8))
    t151=next(x[2] for x in roots if tuple(x[:2])==(151,8))
    check(w['g57_tick']==t57 and w['g151_tick']==t151,'falsified g tick')
    g_idx=t57-1
    check(events[g_idx]['t']==t57 and tuple(events[g_idx]['ip'])==(57,8) and events[g_idx]['op']==103,'root event wrong')
    g=events[g_idx]
    check(len(g['pre'])>=2 and g['post'] and tuple(g['pre'][-2:])==CELL,
          'missing g read address')
    check(w['g57_address']==list(CELL) and w['g57_value']==g['post'][-1],'fake memory read')
    pi=independently_last_written(events,g_idx,CELL,max(0,j_idx-CAP))
    check(pi is not None,'p writer absent')
    p=events[pi]
    check(tuple(p['ip'])==P and w['p60_tick']==p['t'] and w['p60_value']==p['pre'][-3],'writer mismatch')
    intervening=[e['t'] for e in events[pi+1:g_idx] if e['op']==ord('s')]
    check(w['intervening_s']==intervening and not intervening,'s writer between observed p/g')
    check(w['p_to_g_value_match'] is True and p['pre'][-3]==g['post'][-1],'wrong physical p/g values')
    check(w['observed_fungespace_writer'] is True and w['physical_stack_transfer_pass'] is True and
          w['unsupported_steps']==[] and w['status']=='two_physically_observed_g_roots_with_value_matched_p',
          'false lineage classification')
    return {'roots':roots,'g57':t57,'g151':t151,'p60':p['t']}


def hostile(w,events,j_idx):
    mut=[('j_tick',w['j_tick']+1),('j_operand',0 if w['j_operand'] else 61),
         ('j_flag',1-w['j_flag']),('status','unknown'),('g57_tick',w['g57_tick']+1),
         ('g151_tick',w['g151_tick']+1),('p60_tick',w['p60_tick']+1),
         ('g57_value',w['g57_value']+1),('p60_value',w['p60_value']+1),
         ('g57_address',[1,49]),('root_sites',[[999,999,1]]),
         ('physical_stack_transfer_pass',False),('p_to_g_value_match',False),
         ('global_input_byte_owner','input-byte-0'),('stage1_pass',True),
         ('intervening_s',[111]),('observed_fungespace_writer',False),
         ('window_cap',767),('unsupported_steps',[1000])]
    rejected=0
    for key,v in mut:
        bad=copy.deepcopy(w);bad[key]=v
        try:compare(bad,events,j_idx)
        except AssertionError:rejected+=1
        else:raise AssertionError('hostile witness accepted: '+key)
    return rejected


def run(zip_dir,qa31w,witnesses,out):
    rows=load_w_csv(qa31w);pairs,_=selected_pairs(rows)
    labels=sorted({r['label'] for _,a,b in pairs for r in (a,b)})
    records=json.loads(Path(witnesses).read_text(encoding='utf-8'))
    check(len(records)==261,'expected QA31AA 261 witnesses')
    by_case=collections.defaultdict(list)
    for x in records:by_case[x['label']].append(x)
    reader=CaseReader(zip_dir);matched=0;hostile_checks=0
    for label in labels:
        events=reader.load(next(x for x in rows if x['label']==label))
        expected=by_case[label]
        js=[i for i,e in enumerate(events) if e['op']==106 and tuple(e['ip'])==J]
        check(len(expected)==len(js),'extra/missing witness')
        for i,r in zip(js,expected):
            compare(r,events,i);matched+=1
            if hostile_checks==0:hostile_checks=hostile(r,events,i)
    check(matched==261 and hostile_checks==19,'oracle coverage or hostile control count')
    report={'schema':'qa31aa-independent-reverse-signed-original-v1',
        'original_zip_sha256_crc':len(reader.zips),
        'signed_traces':len(reader.processed),
        'signed_steps':sum(reader.processed.values()),
        'reverse_matches':matched,
        'hostile_witness_mutations_rejected':hostile_checks,
        'finite_two_g_roots':matched,'byte_owner':'unknown',
        'stage1_pass':False,'new_native_runs':0}
    Path(out).write_text(json.dumps(report,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,sort_keys=True))
    return report

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--zip-dir',required=True)
    parser.add_argument('--qa31w-csv',required=True);parser.add_argument('--witnesses',required=True)
    parser.add_argument('--out',required=True)
    a=parser.parse_args();run(a.zip_dir,a.qa31w_csv,a.witnesses,a.out)
