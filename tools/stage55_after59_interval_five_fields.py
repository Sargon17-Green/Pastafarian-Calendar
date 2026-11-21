#!/usr/bin/env python3
"""Stage55 AFTER58→AFTER59: bounded independent Python exact interval witness.

The predecessor must match its certified SHA-256. Uses a separate integer
combinatorial insertion DP plus 22 exact small brute-force controls. Not an
oracle for the complete Year 5000, nor a cross-engine soak or final-stage pass.
"""
import argparse
import hashlib
import itertools
import json
import math
import sys
from pathlib import Path

sys.set_int_max_str_digits(0)
PROJECT_ID = 'PC-BRANCH-MATLAB-POLSKI'
PIN = 'f1dac356e01f1aec5ef43bdf403847f0a0f2f5a92558a68a05a63671c5be7174'
PREFIX58 = (1,2,3,4,5,6,7,4,8,9,10,9,11,6,12,13,14,15,16,16,17,7,18,2,19,20,19,5,21,22,9,1,7,23,3,8,23,14,10,9,24,2,25,18,7,15,26,3,3,21,27,22,28,11,5,5,22,18)
KEYS = {'schema','originalLengths','remaining','openedUpTo','closedUpTo',
        'rankDecimal','countDecimal','done','stepsComputed'}


def digest(b):
    return hashlib.sha256(b).hexdigest()


def read_checkpoint(p, expected_digest=None):
    b = Path(p).read_bytes()
    d = digest(b)
    if expected_digest is not None:
        assert d == expected_digest, ('checkpoint SHA-256 mismatch', d)
    obj = json.loads(b)
    assert set(obj) == KEYS and obj['schema'] == 'pastafari-weave-cursor-v1'
    assert isinstance(obj['done'],bool)
    for k in ('rankDecimal','countDecimal'):
        v = obj[k]
        assert isinstance(v,str) and v.isascii() and v.isdigit() and v[0]!='0'
    assert 1<=int(obj['rankDecimal'])<=int(obj['countDecimal'])
    return obj,d


def insertion_count(multiplicities, opened):
    """Exact count via first-occurrence-position polynomial states.

    We fix each new largest symbol's final occurrence at the word's end,
    thereby enforcing ascending last-occurrence order. When its first
    occurrence was not yet opened, it must follow previous first openings.
    """
    assert multiplicities and all(type(x)==int and x>0 for x in multiplicities)
    assert 0<=opened<=len(multiplicities)
    states={1:1}
    size=multiplicities[0]
    for j,quantity in enumerate(multiplicities[1:],2):
        new_states={}; prefix_weight=0; total=sum(states.values())
        for first_position in range(1,size+2):
            prefix_weight += states.get(first_position-1,0)
            eligible = total if j<=opened+1 else prefix_weight
            if quantity==1:
                ways=eligible if first_position==size+1 else 0
            else:
                ways=eligible*math.comb(size+quantity-1-first_position,quantity-2)
            if ways:
                new_states[first_position]=ways
        states=new_states
        size+=quantity
    return sum(states.values())


def brute_count(lengths,already_open):
    pool=tuple(i+1 for i,n in enumerate(lengths) for _ in range(n))
    valid=0
    for arrangement in set(itertools.permutations(pool)):
        first=[arrangement.index(i+1) for i in range(len(lengths))]
        last=[len(arrangement)-1-arrangement[::-1].index(i+1) for i in range(len(lengths))]
        if last==sorted(last) and first[already_open:]==sorted(first[already_open:]):
            valid+=1
    return valid


def derive(after58,fixture):
    p,old_digest=read_checkpoint(after58,PIN)
    f=json.loads(Path(fixture).read_text(encoding='utf-8'))
    L=f['month_lengths']; month_names=f['month_name_indices']
    assert f['year']==5000 and f['first_day']==-15057702
    assert f['cutlet_name_indices'][0]==15
    assert len(L)==len(month_names)==45 and sum(L)==4244
    assert p['originalLengths']==L
    assert len(PREFIX58)==58 and p['stepsComputed']==58
    assert p['openedUpTo']==28 and p['closedUpTo']==0 and p['done'] is False
    a=p['remaining']
    assert a==[x-PREFIX58.count(i) for i,x in enumerate(L,1)]
    assert sum(a)==4186
    small=((1,1),(2,1),(1,2),(2,2),(3,2),(2,3),(2,2,2))
    cases=0
    for lengths in small:
        for opened in range(len(lengths)+1):
            assert insertion_count(lengths,opened)==brute_count(lengths,opened)
            cases+=1
    assert cases==22
    blocks=[]
    for j in range(1,30):
        assert a[j-1]>1
        b=a.copy();b[j-1]-=1
        child_opened=p['openedUpTo']+int(j==p['openedUpTo']+1)
        count=insertion_count(b,child_opened)
        assert count>0
        blocks.append(count)
        print(f'STAGE55_FIFTY_NINTH_INDEPENDENT_BLOCK SYMBOL={j} DIGITS={len(str(count))}',flush=True)
    parent_count=int(p['countDecimal'])
    rank=int(p['rankDecimal'])
    assert len(blocks)==29 and sum(blocks)==parent_count
    offset=0
    chosen=child_rank=child_count=None
    for j,c in enumerate(blocks,1):
        if offset<rank<=offset+c:
            chosen=j;child_rank=rank-offset;child_count=c
            break
        offset+=c
    assert chosen==17 and offset+child_rank==rank and 1<=child_rank<=child_count
    b=a.copy();b[chosen-1]-=1
    opened=p['openedUpTo']+int(chosen==p['openedUpTo']+1)
    assert opened==28 and sum(b)==4185
    month_idx=month_names[chosen-1]
    occurrence=L[chosen-1]-b[chosen-1]
    assert month_idx==3 and occurrence==2 and occurrence==PREFIX58.count(chosen)+1
    row=(f'STAGE55_FIFTY_NINTH_ROW POSITION=59 YEAR=5000 CUTLET_INDEX=15 '
         f'CUTLET_DAY=59 MONTH_INDEX={month_idx} MONTH_DAY={occurrence}')
    report={
        'project_id':PROJECT_ID,'transition':'AFTER58->AFTER59','after58_sha256':old_digest,
        'fixture_year':f['year'],'fixture_first_day':f['first_day'],
        'small_brute_cases':cases,'positive_child_blocks':len(blocks),
        'parent_partition_exact':sum(blocks)==parent_count,'rank_interval_exact':offset<rank<=offset+child_count,
        'parent_count_digits':len(str(parent_count)),'parent_rank_digits':len(str(rank)),
        'selected_symbol':chosen,'child_rank_digits':len(str(child_rank)),
        'child_count_digits':len(str(child_count)),'steps_computed':59,
        'remaining':4185,'opened_up_to':opened,'closed_up_to':0,
        'month_index':month_idx,'month_day':occurrence,'cutlet_index':15,
        'cutlet_day':59,'expected_row':row,'invalid_prefix_positions':[0,60]
    }
    print(f'STAGE55_FIFTY_NINTH_PREFLIGHT_PASS SMALL={cases} BLOCKS={len(blocks)} '
          f'SYMBOL={chosen} STEPS=59 REMAINING=4185 ROW=59/5000/15/59/3/2 '
          f'AFTER58_SHA256={old_digest}',flush=True)
    return p,f,report,b,child_rank,child_count


def verify_after59(after59, parent, fixture, report, child_remaining, child_rank, child_count):
    child,d=read_checkpoint(after59)
    assert child['originalLengths']==parent['originalLengths']==fixture['month_lengths']
    assert child['remaining']==child_remaining and sum(child['remaining'])==4185
    assert child['stepsComputed']==59 and child['openedUpTo']==28
    assert child['closedUpTo']==0 and child['done'] is False
    assert child['rankDecimal']==str(child_rank)
    assert child['countDecimal']==str(child_count)
    print(report['expected_row'],flush=True)
    print(f'STAGE55_FIFTY_NINTH_INDEPENDENT_PASS SMALL=22 BLOCKS=29 '
          f'AFTER58_SHA256={PIN} AFTER59_SHA256={d} REMAINING=4185',flush=True)
    print('STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED')
    print('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED')
    print('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED')
    return d


def main(after58,fixture,after59,report_path):
    parent,f,report,b,rank,count=derive(after58,fixture)
    if after59 is None:
        report['after59_validation']='NOT_RUN_PRE_NATIVE'
    else:
        report['after59_sha256']=verify_after59(after59,parent,f,report,b,rank,count)
        report['after59_validation']='PASS'
    if report_path:
        Path(report_path).write_text(json.dumps(report,sort_keys=True,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('after58',type=Path)
    ap.add_argument('fixture',type=Path)
    ap.add_argument('--after59',type=Path)
    ap.add_argument('--report',type=Path)
    args=ap.parse_args()
    main(args.after58,args.fixture,args.after59,args.report)
