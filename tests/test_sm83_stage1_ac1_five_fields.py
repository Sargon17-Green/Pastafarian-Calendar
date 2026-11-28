#!/usr/bin/env python3
"""Host-only AC.1 five-field differential. Expected values only at comparison.
Uses branch-local year/sauce oracles; V32 exact Node worker, bounded subprocess.
PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
"""
from collections import Counter
from functools import lru_cache
from math import comb, perm
from pathlib import Path
import json
import subprocess
import sys

# The conservative V32 upper bound has fewer than 10,000 decimal digits.
# Keep an explicit finite limit rather than disabling the conversion guard.
if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(12000)

from test_sm83_stage1_year_path_oracle import find_year, gate_at
from test_sm83_stage1_selection_oracle import bowl_answer_flow, select
from test_sm83_stage1_sauce_oracle import compute_sauce

WORKER = Path(__file__).with_name("sm83_v32_shared_prefix_qa.js")
# Normative README 56bc4173aae4975ded019ef5ab5a36249f1424df, AC.1 only.
ROWS = [
(-15055671,-15055671,(5000,10,503,20,56)),
(-15055671,-15055672,(5000,10,502,32,21)),
(-15055671,-15055670,(5000,14,1,29,38)),
(-15055671,-15056171,(5000,10,3,1,29)),
(-15055671,-15055171,(5000,14,500,18,76)),
(-15055671,-15061671,(4999,5,158,43,3)),
(-15055671,-15049671,(5001,12,95,5,81)),
(-15056905,-15056448,(5000,9,167,10,65)),
(-15054437,-15053449,(5000,14,10,1,45)),
(-15058171,-15053171,(5002,5,288,29,13)),
]

def worker(mode, payload=None):
    p = subprocess.run(["node","--max-old-space-size=512",str(WORKER),mode],
        input=json.dumps(payload), text=True, capture_output=True, timeout=180, check=False)
    if p.returncode:
        raise RuntimeError(f'Node {mode} exit={p.returncode}: {p.stderr[-4000:]}')
    return json.loads(p.stdout)

def C(n,k):
    return comb(n,k) if 0 <= k <= n else 0

@lru_cache(maxsize=65536)
def split(g,k,r):
    if k == 0: return int(g == 0 and r == 0)
    if g < k or r < 0 or r >= g: return 0
    if not r: return C(g-1,k-1)
    return sum(C(r-1,j-1)*C(g-r-1,k-j-1) for j in range(1,k))

def unrank(rank, blocks):
    for value,count in blocks:
        if rank <= count:
            assert rank >= 1
            return value,rank
        rank -= count
    raise AssertionError("rank outside blocks")

def cutlets(g,k,r,rank):
    out=[]
    while k:
        a,rank=unrank(rank,((a,split(g-a,k-1,max(0,r-a)))
                           for a in range(1,g-k+2) if not r or a<=r))
        out.append(a)
        g-=a; k-=1; r=max(0,r-a)
    assert g==r==0 and rank==1
    return out

def names(n,k,rank):
    out=[]; unused=list(range(1,n+1))
    while k:
        block=perm(len(unused)-1,k-1)
        i,rem=divmod(rank-1,block)
        out.append(unused.pop(i));rank=rem+1;k-=1
    assert rank==1 and len(out)==len(set(out))
    return out

def length_rows(m,L):
    # Independent sliding-window exact DP, not inclusion-exclusion.
    row=[1]+[0]*L; rows=[row]
    for _ in range(m):
        acc=0; nxt=[]
        for s in range(L+1):
            if s>=4: acc+=row[s-4]
            if s>=124: acc-=row[s-124]
            nxt.append(acc)
        rows.append(nxt);row=nxt
    return rows

def lengths(m,L,rank,rows):
    out=[]
    while m:
        a,rank=unrank(rank,((a,rows[m-1][L-a])
                            for a in range(4,min(123,L)+1)))
        out.append(a);L-=a;m-=1
    assert L==0 and rank==1
    return out

@lru_cache(maxsize=10)
def structure(c,oi,ci,opening,closing):
    gates=[gate_at(i) for i in range(oi,ci+1)]
    assert gates[0]==opening and gates[-1]==closing
    g=ci-oi; L=closing-opening
    sauce=compute_sauce(c,opening+1)
    def ask(bowl,seal,n):
        return select(bowl_answer_flow(sauce,bowl,seal),n).rank
    K=5+ask(2,20,min(17,g)-5)
    r=gates.index(c) if c in gates[1:-1] else 0
    count=split(g,K,r); cr=ask(2,21,count)
    xs=cutlets(g,K,r,cr)
    bounds=[opening]; pos=0
    for x in xs:
        pos+=x;bounds.append(gates[pos])
    assert bounds[-1]==closing and (not r or c in bounds[1:-1])
    cn=names(17,K,ask(5,22,perm(17,K)))
    lo=(L+122)//123; hi=min(47,L//4)
    m=lo-1+ask(3,30,hi-lo+1)
    rows=length_rows(m,L)
    N=rows[m][L]; lr=ask(3,31,N)
    ls=lengths(m,L,lr,rows)
    assert sum(ls)==L and len(ls)==m and all(4<=v<=123 for v in ls)
    flow=bowl_answer_flow(sauce,4,32)
    result=worker("--actual",{"lengths":ls,"first":str(flow.first),"step":flow.step})
    vn=int(result["count"]); vr=int(result["rank"])
    choice=select(flow,vn)
    assert (vr,result["digits"])==(choice.rank,choice.digits)
    word=result["word"]
    assert len(word)==L and Counter(word)==Counter(dict(enumerate(ls)))
    first=[word.index(i) for i in range(m)]
    last=[L-1-word[::-1].index(i) for i in range(m)]
    assert first==sorted(first) and last==sorted(last)
    mn=names(47,m,ask(5,33,perm(47,m)))
    # Compact evidence excludes the whole word but retains exact lengths/ranks.
    print("HOST_AC1_STRUCTURE="+json.dumps({
        "c":c,"open":opening,"close":closing,"g":g,"K":K,"cutletRank":str(cr),
        "monthLengths":ls,"lengthRank":str(lr),"v32Count":str(vn),
        "v32Rank":str(vr),"digits":choice.digits,"stats":result["stats"],
        "countStats":result["countStats"],"maxRSSKiB":result["maxRSSKiB"],
        "heapEndBytes":result["heapEndBytes"],"elapsedMs":result["elapsedMs"]}),flush=True)
    return bounds,cn,word,mn

def main():
    print("HOST_V32_LATE="+json.dumps(worker("--late")),flush=True)
    checked=0; mismatches=[]
    for i,(c,t,expected) in enumerate(ROWS,1):
        y=find_year(c,t); s=y.span
        bounds,cn,word,mn=structure(c,s.open_index,s.close_index,s.open_gate,s.close_gate)
        p=next(j for j in range(len(cn)) if bounds[j]<t<=bounds[j+1])
        d=t-s.open_gate; label=word[d-1]
        got=(y.year_number,cn[p],t-bounds[p],mn[label],word[:d].count(label))
        print("HOST_AC1_ROW="+json.dumps({"row":i,"actual":got,"expected":expected}),flush=True)
        for j,(a,b) in enumerate(zip(got,expected)):
            checked+=1
            if a!=b: mismatches.append((i,j,a,b))
    assert checked==50 and not mismatches,mismatches
    print("HOST_STAGE1_AC1_FIVE_FIELDS=PASS rows=10 fields=50",flush=True)

if __name__=="__main__":
    main()
