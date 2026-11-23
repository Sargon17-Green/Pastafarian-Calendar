#!/usr/bin/env python3
"""Original Ada ticket-stream *source-only* reachability theorem.

Only synthetic integers, not original Calendar_Date/F(c,t). The original Ada
and Python source SHA references are pinned in the adjacent v186 report.
"""
from collections import Counter
from itertools import combinations
from math import factorial, lcm
import hashlib, json

M=(1<<127)-1

def ticket(first,step,i,slots,mod=M):
    assert 1<=first<=mod and step in (-1,1) and 1<=slots<=mod
    x=1+((first-1+step*i)%mod)
    a=(mod//slots)*slots
    if x>a:x=a if step==-1 else 1
    return 1+((x-1)%slots)

def ticket_literal(first,step,i,slots,mod):
    # An independent finite cyclic walk for the toy modulus.
    x=1+((first-1+step*i)%mod)
    a=(mod//slots)*slots
    for _ in range(mod):
        if x<=a:return 1+((x-1)%slots)
        x=1+((x-1+step)%mod)
    raise AssertionError("walk never accepted")

def weave(lengths,choices):
    rem=[x-2 for x in lengths]
    out=list(range(1,len(lengths)+1))
    for t in choices:
        for j in range(len(rem)):
            if t>rem[j]:t-=rem[j]
            else:
                assert rem[j]>0
                rem[j]-=1;out.append(j+1);break
        else:raise AssertionError("unassigned ticket")
    assert not any(rem)
    return tuple(out+list(range(1,len(lengths)+1)))

def legal(lengths,w):
    m=len(lengths)
    if len(w)!=sum(lengths):return False
    if any(w.count(j)!=lengths[j-1] for j in range(1,m+1)):return False
    first=[w.index(j) for j in range(1,m+1)]
    last=[len(w)-1-w[::-1].index(j) for j in range(1,m+1)]
    return first==sorted(first) and last==sorted(last)

def toy_count():
    # Enumerate all 12!/(4!^3)=34650 distinct multiset words exactly once.
    count=0
    for p1 in combinations(range(12),4):
        remaining=[i for i in range(12) if i not in p1]
        for p2 in combinations(remaining,4):
            w=[3]*12
            for i in p1:w[i]=1
            for i in p2:w[i]=2
            count+=int(legal((4,4,4),tuple(w)))
    return count

def reachable_toy():
    lengths=(4,4,4);k=6
    period=lcm(*range(1,k+1))
    # Every first in [2k+1, M-2k] is non-wrapping and accepted. All
    # local ticket residues repeat modulo lcm(1..k).
    assert period==60 and 2*k+period<M-2*k
    boundary=list(range(1,2*k+1))+list(range(M-2*k+1,M+1))
    observed=set()
    for step in (-1,1):
        for x in list(range(2*k+1,2*k+1+period))+boundary:
            observed.add(weave(lengths,tuple(ticket(x,step,i,k-i) for i in range(k))))
    assert len(observed)==40
    return len(observed)

def valid_year_counterexample():
    lengths=(84,84,84);k=246
    # An actually admissible 252-day year with three months, each 84 days.
    interior=(1,2,2)+(1,)*81+(2,)*80+(3,)*82
    w=(1,2,3)+interior+(1,2,3)
    assert len(w)==252 and legal(lengths,w)
    # Inverse the first three fixed-rail interior choices. The tickets
    # are (1,82,82): first ticket odd, third even.
    rem=[82,82,82];required=[]
    for label in interior:
        required.append(sum(rem[:label-1])+1)
        rem[label-1]-=1
    assert tuple(required[:3])==(1,82,82)
    assert weave(lengths,tuple(required))==w
    # For 2K+1 <= x <= M-2K, all three candidates are accepted with no
    # wrap. Since K=246 and K-2=244 are even, ticket 0 and ticket 2
    # must have equal parity, contradicting 1 and 82.
    assert k%2==0 and (k-2)%2==0 and required[0]%2!=required[2]%2
    checked=0
    for step in (-1,1):
        for x in list(range(1,2*k+1))+list(range(M-2*k+1,M+1)):
            checked+=1
            assert tuple(ticket(x,step,i,k-i) for i in range(3))!=(1,82,82)
    assert checked==1968
    return {'days':252,'months':3,'lengths':list(lengths),
            'required_tickets':required[:3],
            'boundary_streams_exhausted':checked,
            'legal_unreachable_weave_sha256':hashlib.sha256(bytes(w)).hexdigest()}

def self_check():
    checks=0
    for k in (4,6,8):
        for first in range(1,258):
            for step in (-1,1):
                for i in range(k):
                    assert ticket(first,step,i,k-i,257)==ticket_literal(first,step,i,k-i,257)
                    checks+=1
    assert checks==9252
    return checks

def main():
    data={'schema':'PC_ISSUE29_SOURCE_ONLY_REACHABILITY_V186/1',
          'toy_full_family':toy_count(),'toy_fixed_rail_family':90,
          'toy_source_stream_reachable_fixed_rails':reachable_toy(),
          'whole_year_example':valid_year_counterexample(),
          'independent_toy_modulus_literal_walk_checks':self_check(),
          'original_calendar_F_calls':0,'native_converter_runs':0}
    assert (data['toy_full_family'],data['toy_source_stream_reachable_fixed_rails'])==(1301,40)
    print(json.dumps(data,sort_keys=True,indent=2))

if __name__=='__main__':
    main()
