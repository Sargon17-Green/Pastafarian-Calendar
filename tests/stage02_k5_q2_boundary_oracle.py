#!/usr/bin/env python3
"""Independent bounded ring-walk oracle for k=5, q=2; no WASM imports."""
from __future__ import annotations
import json
PROJECT_ID='PC-BRANCH-WAT-SPANISH'
M=(1<<127)-1
BASES=(17,19,21)
CASES=(('forward_exact',1,0),('forward_skip',1,1),
       ('backward_exact',-1,0),('backward_two_rejections',-1,1))
def check(base,step,offset,bounded):
    first=base-(5 if step==1 else 1)
    x,digit,weight=1,first,1
    for _ in range(5):
        x+=(digit-1)*weight
        digit=1+(digit-1+step)%base
        weight*=base
    space=base**5
    closed=(space-(base**4+2*base**3+3*base**2+4*base+5) if step==1
            else space-(5*base**4+4*base**3+3*base**2+2*base+1))
    assert x==closed and x%2==0
    n=x//2-offset
    assert base**4<n<space and space//n==2
    limit=2*n
    assert limit==x-2*offset
    accepted=x if not offset else 1 if step==1 else limit
    reject=0 if not offset else space-x+1 if step==1 else 2
    if bounded:
        cursor,steps=x,0
        while cursor>limit:
            cursor=1+(cursor-1+step)%space
            steps+=1
            assert steps<=250000
        assert (cursor,steps)==(accepted,reject)
    rank=(accepted-1)%n+1
    assert rank==(1 if step==1 and offset else n)
    assert digit==(base if step==1 else base-6)
    return {'n':str(n),'rank':str(rank),'rejections':str(reject)},reject
def verify():
    ncases=nreject=0
    for b in BASES:
        for _,step,offset in CASES:
            _,r=check(b,step,offset,True)
            ncases+=1
            nreject+=r
    assert (ncases,nreject)==(12,453914)
    prod={name:check(M,step,offset,False)[0] for name,step,offset in CASES}
    return {'project_id':PROJECT_ID,'bounded_cases':ncases,
            'bounded_rejection_steps':nreject,'production_cases':prod,
            'failed':0,'native':'NOT_EXECUTED_BY_PYTHON'}
if __name__=='__main__':
    print(json.dumps(verify(),sort_keys=True))
