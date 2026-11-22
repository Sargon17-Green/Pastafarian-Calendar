#!/usr/bin/env python3
"""Independent count/rank oracle: real canonical month_names=DistinctNames(47,47)."""
import hashlib
import itertools
import json
import math

M=(1<<127)-1
def prime_factorial(n):
    out=1
    for p in range(2,n+1):
        if any(p%d==0 for d in range(2, math.isqrt(p)+1)): continue
        exponent=0
        q=n
        while q:
            q//=p
            exponent+=q
        out*=p**exponent
    return out
def rank_case(n,direction):
    space=M
    k=1
    while space<n:
        space*=M
        k+=1
    first=1 if direction=="forward" else M
    step=1 if direction=="forward" else -1
    x=1
    for j in range(k):
        x+=((first-1+step*j)%M)*(M**j)
    limit=(space//n)*n
    rejected=x>limit
    accepted=(1 if step==1 else limit) if rejected else x
    result=1+(accepted-1)%n
    return {"rejected":rejected,"rank_decimal":str(result),
            "rank_sha256":hashlib.sha256(str(result).encode()).hexdigest(),
            "minimal_k":k}
def main():
    n=prime_factorial(47)
    assert n==math.prod(range(1,48))
    assert len(list(itertools.permutations(range(5),3)))==60
    assert n==258623241511168180642964355153611979969197632389120000000000
    # All canonically valid year lengths admit month-count candidate m=47.
    assert all((y+122)//123<=47<=min(47,y//4) for y in range(252,5779))
    assert M<n<M*M
    fw=rank_case(n,"forward")
    bw=rank_case(n,"backward")
    assert fw["rejected"] is False and bw["rejected"] is True
    assert fw["rank_sha256"]=="af77b83c02097ff201ed0848390024fb04773c58b236a09dfa5ea2dbf3b3adce"
    assert bw["rank_sha256"]=="b3cafdb279a6d89eb83c8cf0647bdb383d73cf4102ddf07c71dc1b09f885cfc5"
    assert int(bw["rank_decimal"])==n
    print(json.dumps({"project":"PC-BRANCH-WAT-SPANISH",
      "source":"Pastafarian_Canon_Discrete_Formulation_2026-10-19.md",
      "scope":"family_cardinality_and_rank_math_only",
      "family":"DistinctNames(47,47)","n":str(n),"n_bits":n.bit_length(),
      "forward":fw,"backward":bw,"native_tested_here":False,
      "stage02_accepted":False},sort_keys=True))
if __name__=="__main__":
    main()
