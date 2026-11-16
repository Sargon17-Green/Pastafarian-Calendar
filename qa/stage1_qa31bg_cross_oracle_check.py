#!/usr/bin/env python3
"""Deterministic QA31BG two-oracle comparison (no original Native execution)."""
import json,sys,collections
from pathlib import Path

def verify(primary,independent):
    a=json.loads(Path(primary).read_text(encoding='utf-8'))
    b=json.loads(Path(independent).read_text(encoding='utf-8'))
    assert a['project_id']==b['project_id']=='PC-BRANCH-BEFUNGE98-KYRGYZ'
    assert a['original_outer_zip_sha256']==b['original_outer_zip_sha256']
    assert a['original_index_zip_sha256']==b['original_index_zip_sha256']
    def key(w,kind):
        return w['shard'],w['trace_sha256' if kind=='a' else 'compressed_sha256'],w['second_x_t' if kind=='a' else 'x_t']
    aa={key(w,'a'):w for w in a['witnesses']}
    bb={key(w,'b'):w for w in b['witnesses']}
    assert aa.keys()==bb.keys() and len(aa)==225
    deltas=collections.Counter()
    for k,x in aa.items():
        y=bb[k]
        for field in ('p43_t','p43_value','g43a_t','g43b_t','p53_t','p53_value'):
            assert x[field]==y[field],(k,field,x[field],y[field])
        assert x['owner_t']==x['p43_t']
        assert x['p53_value']-x['p43_value']==y['p53_conditional_g43_0']
        assert y['p53_conditional_g43_1']==y['p53_conditional_g43_0']+1
        assert y['end_stack_tainted_slots']==1 and y['end_stack_differs_0_1']
        assert (x['branch_x_count'],x['branch_j_count'])==(26,0)
        assert (y['first_branch_count'],y['second_branch_count'])==(1,3)
        deltas[x['p53_value']-x['p43_value']]+=1
    assert deltas=={0:144,1:9,2:9,3:9,4:9,5:9,6:9,7:9,8:9,9:9},deltas
    assert len(a['hostile_rejected'])==len(set(a['hostile_rejected']))==18
    print('QA31BG_CROSS_ORACLE_PASS: 225/225 matched physical/counterfactual witnesses; 18/18 hostile rejected')
    print('QA31BG_DELTA_COUNTS',dict(sorted(deltas.items())))
if __name__=='__main__':
    if len(sys.argv)!=3:raise SystemExit('crosscheck.py physical.json independent.json')
    verify(*sys.argv[1:])
