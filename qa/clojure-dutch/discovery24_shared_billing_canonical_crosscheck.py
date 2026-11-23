#!/usr/bin/env python3
"""Independent DISCOVERY24 QA: brute-prefix cost oracle and a second canonical counter.

Never calls Clojure or changes production. Tiny oracle enumerates whole words, so
it shares neither the production suffix counter nor the prior QA insertion code.
The canonical counter is a separate first-position/gap convolution over integers.
"""
import argparse
from collections import defaultdict, Counter
from functools import lru_cache
from hashlib import sha256
from itertools import permutations
from math import comb
import json
import zipfile

PROJECT = 'PC-BRANCH-CLOJURE-DUTCH'
ARTIFACT_SHA = 'eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5'
SOURCE_SHA = 'ec0051ec6335fe178c03bcf3583b3dbfec1ffa84'
PRODUCTION_BLOB = '62f304dc013a9a9f70475bb0d34f186838b27318'
EXPECTED_PREFIX_HASH = '2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a'
BUDGET = 5_000_000


def legal_words(profile):
    alphabet = tuple(i+1 for i,k in enumerate(profile) for _ in range(k))
    result = []
    for w in sorted(set(permutations(alphabet))):
        first = [w.index(i) for i in range(1,len(profile)+1)]
        last = [len(w)-1-w[::-1].index(i) for i in range(1,len(profile)+1)]
        if first == sorted(first) and last == sorted(last):
            result.append(w)
    return result


def brute_prefix_oracle(profile):
    words = legal_words(profile)
    blocks = defaultdict(list)
    for word in words:
        for n in range(len(word)+1):
            blocks[word[:n]].append(word)
    assert words and all(w[0]==1 for w in words)
    tested=refused=opened_edges=closed_edges=simultaneous_edges=active_groups=new_groups=0
    skipped_candidates=0
    for rank,word in enumerate(words,1):
        for target in range(1,len(word)+1):
            prefix=(1,)
            billed=0
            residual_rank=rank
            for depth in range(1,target):
                remaining=Counter(profile[i] for i in []) # explicit independent mutable-count rebuild below
                remaining={i+1:profile[i]-prefix.count(i+1) for i in range(len(profile))}
                opened=max(prefix)
                closed=0
                while closed<len(profile) and remaining[closed+1]==0: closed+=1
                R=sum(remaining.values())
                children=[(v,len(blocks[prefix+(v,)])) for v in range(1,len(profile)+1)
                          if blocks.get(prefix+(v,))]
                active=[(v,k) for v,k in children if v<=opened]
                newer=[(v,k) for v,k in children if v==opened+1]
                assert len(active)+len(newer)==len(children) and len(newer)<=1
                # Literal production formula: (1 + (month_count-opened)*R), once
                # per nonempty active group, followed by (1+(m-opened-1)*R)
                # only when all active candidates were skipped.
                old_charge=1+(len(profile)-opened)*R
                new_charge=1+(len(profile)-opened-1)*R
                candidate=word[depth]
                assert candidate in [v for v,_ in children]
                if active:
                    billed+=old_charge
                    active_groups+=1
                if candidate==opened+1:
                    billed+=new_charge
                    new_groups+=1
                    opened_edges+=1
                for v,k in children:
                    if v<candidate: residual_rank-=k; skipped_candidates+=1
                    if v==candidate:break
                assert 1<=residual_rank<=len(blocks[prefix+(candidate,)])
                if remaining[candidate]==1:
                    closed_edges+=1
                    if candidate==opened+1:simultaneous_edges+=1
                prefix=prefix+(candidate,)
            assert prefix==word[:target]
            # The exact budget must be accepted; if it is above 1, minus one
            # must refuse at the first group that would cross the threshold.
            for budget,should_accept in ((max(1,billed),True),(billed-1,False)):
                if budget<1:continue
                charge_seen=0
                for depth in range(1,target):
                    p=word[:depth]
                    remaining={i+1:profile[i]-p.count(i+1) for i in range(len(profile))}
                    op=max(p)
                    R=sum(remaining.values())
                    exists_active=any(blocks.get(p+(v,)) for v in range(1,op+1))
                    group_cost=(1+(len(profile)-op)*R if exists_active else 0)
                    if word[depth]==op+1:
                        group_cost+=1+(len(profile)-op-1)*R
                    charge_seen+=group_cost
                    if charge_seen>budget:break
                accepted=charge_seen<=budget
                assert accepted==should_accept,(profile,rank,target,budget,billed)
                if should_accept:tested+=1
                else:refused+=1
    return dict(profile=profile,words=len(words),rank_prefixes=tested,minus_one_refusals=refused,
                first_open_edges=opened_edges,last_close_edges=closed_edges,
                simultaneous_open_close_edges=simultaneous_edges,
                charged_active_groups=active_groups,charged_new_groups=new_groups,
                skipped_candidate_blocks=skipped_candidates)


def valid_children(state):
    rest,opened,closed=state
    for label in range(1,min(len(rest),opened+1)+1):
        n=rest[label-1]
        if not n or (n==1 and label!=closed+1):continue
        rr=list(rest);rr[label-1]-=1
        yield label,(tuple(rr),max(opened,label),closed+int(n==1))


@lru_cache(maxsize=1024)
def gap_factor(length, future, must_follow_first):
    """Normalized gap insertion count. Memoized by the future multiset only."""
    if not future:return 1
    histogram=([0,1] if must_follow_first else None)
    for amount in future:
        coeff=[1]*(length+1)
        if amount>=2:
            for idx in range(1,length+1):
                coeff[idx]=coeff[idx-1]*(idx+amount-2)//idx
        nxt=[0]*(length+amount+1)
        running=0
        for gap in range(length+1):
            if histogram is None:
                possibilities=1
            else:
                if gap<len(histogram):running+=histogram[gap]
                possibilities=running
            ways=1 if gap==length else (coeff[length-gap] if amount>=2 else 0)
            nxt[gap+1]=possibilities*ways
        histogram=nxt
        length+=amount
    return sum(histogram)

@lru_cache(maxsize=1800)
def convolution_count(state):
    """Separate combinatorial decomposition, not production tel-rest."""
    rest,opened,closed=state
    if not any(rest):return 1
    if opened==closed:
        return gap_factor(rest[closed],rest[closed+1:],True)
    active_days=rest[closed]
    active_factor=1
    for label in range(closed+1,opened):
        amount=rest[label]
        active_days+=amount
        active_factor*=comb(active_days-1,amount-1)
    return active_factor*gap_factor(active_days,rest[opened:],False)


def canonical_crosscheck(path):
    raw=open(path,'rb').read()
    assert sha256(raw).hexdigest()==ARTIFACT_SHA,'artifact digest mismatch'
    with zipfile.ZipFile(path) as archive:
        data=json.loads(archive.read('discovery24_canonical_dp_input.json'))
        result=json.loads(archive.read('discovery24_canonical_dp_result.json'))
    assert data['project_id']==PROJECT and data['source_sha']==SOURCE_SHA
    assert result['source_sha']==SOURCE_SHA
    profile=tuple(data['profile']); rank=int(data['weaving_rank'])
    assert (len(profile),sum(profile),len(data['weaving_rank']))==(33,3569,5288)
    total=convolution_count((profile,0,0))
    assert total==int(data['weaving_total']) and 1<=rank<=total
    state=(profile,0,0);prefix=[];spent=0;tested=skipped=0
    schedule=[]
    while len(prefix)<82:
        rest,opened,closed=state
        choices=list(valid_children(state))
        assert choices
        if not prefix:
            assert choices[0][0]==1
            state=choices[0][1];prefix.append(1);continue
        R=sum(rest); m=len(rest)
        active=[x for x in choices if x[0]<=opened]
        newer=[x for x in choices if x[0]==opened+1]
        if active:
            charged=1+(m-opened)*R
            if spent+charged>BUDGET:
                refusal=dict(position=len(prefix)+1,group='ACTIVE',billed=spent,charge=charged,required=spent+charged,opened=opened,closed=closed,remaining=R)
                break
            spent+=charged;schedule.append(('ACTIVE',len(prefix)+1,charged))
        selected=False
        for label,child in active:
            n=convolution_count(child);tested+=1
            if rank>n:rank-=n;skipped+=1
            else:prefix.append(label);state=child;selected=True;break
        if selected:continue
        assert len(newer)==1
        charge=1+(m-opened-1)*R
        if spent+charge>BUDGET:
            refusal=dict(position=len(prefix)+1,group='NEW',billed=spent,charge=charge,required=spent+charge,opened=opened,closed=closed,remaining=R)
            break
        spent+=charge;schedule.append(('NEW',len(prefix)+1,charge))
        label,child=newer[0]
        n=convolution_count(child);tested+=1
        assert rank<=n
        prefix.append(label);state=child
    else:raise AssertionError('unexpected 82-symbol success under budget')
    digest=sha256(','.join(map(str,prefix)).encode('ascii')).hexdigest()
    assert len(prefix)==81 and digest==EXPECTED_PREFIX_HASH
    assert (refusal['position'],refusal['group'],refusal['billed'],refusal['required'])==(82,'ACTIVE',4995675,5002652)
    assert (tested,skipped)==(1173,1093)
    assert spent==sum(e[2] for e in schedule)
    return dict(months=len(profile),days=sum(profile),rank_digits=len(data['weaving_rank']),total_digits=len(str(total)),
      canonical_total_matches_artifact=True, certified_prefix_length=len(prefix),
      certified_prefix_sha256=digest, certified_first_open_count=max(prefix),
      refusal=refusal, rank_candidate_blocks_tested=tested,rank_candidate_blocks_skipped=skipped,
      charged_active_groups=sum(e[0]=='ACTIVE' for e in schedule),charged_new_groups=sum(e[0]=='NEW' for e in schedule),
      unchanged_budget=BUDGET,production_blob=PRODUCTION_BLOB)


def main():
    import sys
    if hasattr(sys,'set_int_max_str_digits'):sys.set_int_max_str_digits(25000)
    p=argparse.ArgumentParser();p.add_argument('--artifact-zip',required=True)
    args=p.parse_args()
    profiles=((2,2),(2,3),(3,2),(2,2,2),(2,3,2),(3,2,2),(2,2,2,2),(4,4))
    tiny=[brute_prefix_oracle(x) for x in profiles]
    assert all(x['rank_prefixes']>0 and x['minus_one_refusals']>0 for x in tiny)
    canon=canonical_crosscheck(args.artifact_zip)
    print(json.dumps(dict(project_id=PROJECT,qa='PASS',small_profiles=tiny,
        tiny_totals={key:sum(x[key] for x in tiny) for key in ('words','rank_prefixes','minus_one_refusals',
                  'first_open_edges','last_close_edges','charged_active_groups','charged_new_groups')},
        canonical=canon,ci='NOT_RUN',native='NOT_RUN',five_field='NOT_RUN',stage2='OPEN'),ensure_ascii=False))

if __name__=='__main__':main()
