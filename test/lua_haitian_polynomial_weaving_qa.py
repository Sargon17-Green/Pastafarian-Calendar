#!/usr/bin/env python3
"""QA-only exact weaving count/unrank: ordered first and last label appearances.
PROJECT_ID=PC-BRANCH-LUA-HAITIAN. No normative Lua, real weaving or full date.
"""
import argparse
import hashlib
import itertools
import math
import sys
import time

if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(20000)

# Attested Lua month-vector log: run 44948262844, job 136980280634,
# source SHA 14e4a60abb9f3f6da61dd7f7156f88dff77a0569.
ACTUAL = (123,92,119,123,121,120,116,116,95,114,120,121,115,116,104,113,
          121,120,119,117,123,86,123,117,115,108,81,116,120,112,120,116,
          115,120,123,114,123,89,122,116,115,79,117,123,92,122,82)

class BudgetExceeded(Exception):
    pass

def build_table(n):
    if not n or any(type(x) is not int or x < 2 for x in n):
        raise ValueError('INVALID_MONTH_LENGTHS')
    p=[0]
    for x in n: p.append(p[-1]+x)
    if len(n)>47 or p[-1]>6000 or sum(x+1 for x in p)>180000:
        raise BudgetExceeded('QA_TABLE_CAP_NOT_NORMATIVE_INVALIDITY')
    t=[None]*(len(n)+1)
    t[-1]=[1]*(p[-1]+1)
    for a in range(len(n)-1,-1,-1):
        r=n[a]-2
        nextrow=t[a+1]
        row=[nextrow[n[a]-1]]
        for q in range(1,p[a]+1):
            row.append(row[-1]+math.comb(q+r,r)*nextrow[q+n[a]-1])
        t[a]=row
    return t

def state(n,prefix):
    rem=list(n);a=b=0
    for i in prefix:
        if type(i) is not int or not 0<=i<len(n) or rem[i]==0: return None
        if rem[i]==n[i]:
            if i!=a:return None
            a+=1
        elif rem[i]==1:
            if i!=b:return None
            b+=1
        elif not b<=i<a:return None
        rem[i]-=1
    return rem,a,b

def suffix_count(rem,a,b,t):
    q=0;active=1
    for i in range(b,a):
        r=rem[i]
        assert r>0
        q+=r
        active*=math.comb(q-1,r-1)
    return active*t[a][q]

def count(n,prefix=(),t=None):
    if t is None:t=build_table(n)
    s=state(n,prefix)
    return suffix_count(*s,t) if s is not None else 0

def unrank(n,rank,t=None,cap=None):
    """Exact one-based lexicographic unrank; cap limits QA prefix output only."""
    if t is None:t=build_table(n)
    if type(rank) is not int or not 1<=rank<=t[0][0]:
        raise ValueError('INVALID_RANK')
    rem=list(n);a=b=q=0;active=1;word=[]
    limit=sum(n) if cap is None else min(cap,sum(n))
    for _ in range(limit):
        tails={};num=den=1;cumulative=q
        for i in range(a-1,b-1,-1):
            r=rem[i]
            tails[i]=(num,den,cumulative)
            if i>b:
                num*=cumulative-r
                den*=cumulative-1
                g=math.gcd(num,den);num//=g;den//=g
            cumulative-=r
        assert cumulative==0
        for i in range(b,a+1):
            if i==a:
                if a==len(n):continue
                newactive=active*math.comb(q+n[a]-2,n[a]-2)
                block=newactive*t[a+1][q+n[a]-1]
                na,nb,nq=a+1,b,q+n[a]-1
            else:
                r=rem[i]
                if r==1 and i!=b:continue
                x,y,c=tails[i]
                if r==1:
                    assert i==b and c==1
                    na,nb=a,b+1
                else:
                    x*=r-1;y*=c-1
                    na,nb=a,b
                numerator=active*x
                assert numerator%y==0
                newactive=numerator//y
                block=newactive*t[a][q-1]
                nq=q-1
            if rank>block:
                rank-=block
            elif block:
                word.append(i);rem[i]-=1
                a,b,q,active=na,nb,nq,newactive
                break
        else:raise AssertionError('NO_LEX_BLOCK')
    if limit==sum(n):assert rank==1 and q==0 and active==1 and not any(rem)
    return tuple(word),rank

def oracle(n):
    rem=list(n);word=[];out=[];L=sum(n)
    def visit():
        if len(word)==L:
            first=[word.index(i) for i in range(len(n))]
            last=[L-1-word[::-1].index(i) for i in range(len(n))]
            if first==sorted(first) and last==sorted(last):out.append(tuple(word))
            return
        for i in range(len(n)):
            if rem[i]:
                rem[i]-=1;word.append(i);visit();word.pop();rem[i]+=1
    visit()
    return out

def small_checks():
    fixtures=[x for m in range(1,4) for x in itertools.product((2,3,4),repeat=m) if sum(x)<=12]
    fixtures += [(2,2,2,2),(2,3,2,2),(3,2,2,2),(3,3,2,2)]
    counters=[0,0,0]
    for n in fixtures:
        t=build_table(n);words=oracle(n)
        assert count(n,t=t)==len(words)
        counters[0]+=1
        probe={(),(0,),(len(n)-1,),(0,0)}
        if words:
            for k in (0,len(words)//2,len(words)-1):probe.add(words[k][:min(4,sum(n))])
        for p in probe:
            assert count(n,p,t)==sum(w[:len(p)]==p for w in words),(n,p)
            counters[1]+=1
        if words:
            for k in sorted({0,len(words)//2,len(words)-1}):
                assert unrank(n,k+1,t)[0]==words[k]
                counters[2]+=1
    assert counters==[43,290,122],counters
    for m in range(1,13):
        assert count((2,)*m)==math.comb(2*m,m)//(m+1)
    for bad in ((),(1,),(2,1),(2,2.0)):
        try:build_table(bad)
        except ValueError:pass
        else:raise AssertionError('INVALID_ACCEPTED')
    for bad in (0,3):
        try:unrank((2,2),bad)
        except ValueError:pass
        else:raise AssertionError('RANK_ACCEPTED')
    assert count((2,2),(1,))==0
    assert count((2,2),(0,0,1,1))==1
    assert count((2,2),(0,0,1,1,1))==0
    try:build_table((123,)*48)
    except BudgetExceeded:pass
    else:raise AssertionError('CAP_MISSED')
    print('POLYNOMIAL_WEAVING_COUNTS_PASS: 43/43')
    print('POLYNOMIAL_WEAVING_PREFIX_PASS: 290/290')
    print('POLYNOMIAL_WEAVING_UNRANK_PASS: 122/122')
    print('POLYNOMIAL_WEAVING_CATALAN_PASS: 12/12')
    print('POLYNOMIAL_WEAVING_GUARDS_PASS: 10/10')

def large_checks():
    n=(113,)*30+(112,)*17
    assert sum(n)==5294
    start=time.perf_counter();t=build_table(n)
    W=t[0][0]
    print('SYNTHETIC_M47_L5294_TABLE_CELLS:',sum(map(len,t)))
    print('SYNTHETIC_M47_L5294_TOTAL_DIGITS:',len(str(W)))
    print('SYNTHETIC_TABLE_BUILD_SECONDS:',round(time.perf_counter()-start,6))
    for name,k in [('FIRST',1),('MIDDLE',(W+1)//2),('LAST',W)]:
        start=time.perf_counter();word,left=unrank(n,k,t)
        assert left==1 and len(word)==5294
        assert tuple(sorted(range(47),key=word.index))==tuple(range(47))
        assert tuple(sorted(range(47),key=lambda i:len(word)-1-word[::-1].index(i)))==tuple(range(47))
        print('SYNTHETIC_FULL_UNRANK_'+name+': PASS; seconds='+str(round(time.perf_counter()-start,6)))
    start=time.perf_counter();real_t=build_table(ACTUAL)
    real=real_t[0][0]
    assert len(ACTUAL)==47 and sum(ACTUAL)==5294
    for k in (1,(real+1)//2,real):
        pre,remrank=unrank(ACTUAL,k,real_t,cap=96)
        assert len(pre)==96 and 1<=remrank<=count(ACTUAL,pre,real_t)
    print('ATTESTED_MONTH_VECTOR_SOURCE_RUN: 44948262844/136980280634')
    print('ATTESTED_M47_L5294_EXACT_COUNT_DIGITS:',len(str(real)))
    print('ATTESTED_M47_L5294_EXACT_COUNT_SHA256:',hashlib.sha256(str(real).encode()).hexdigest())
    print('ATTESTED_M47_L5294_TABLE_CELLS:',sum(map(len,real_t)))
    print('ATTESTED_M47_L5294_96_PREFIXES: 3/3')
    print('ATTESTED_TABLE_AND_PREFIX_SECONDS:',round(time.perf_counter()-start,6))
    print('NORMATIVE_CHOOSE_RANK=NOT_RUN; NORMATIVE_WEAVING=NOT_RUN; FULL_DATE=NOT_RUN; PRODUCTION=UNCHANGED')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--large',action='store_true')
    a=p.parse_args();small_checks()
    if a.large:large_checks()
