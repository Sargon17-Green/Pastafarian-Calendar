#!/usr/bin/env python3
"""Issue29 v187: no F(c,t); witness bounds and forced unique suffix tickets.

Standalone source-mathematical proof. This NEVER calls or imports original
Ada/Python date-converter code, even in its GitHub Actions source check.
"""
from collections import Counter
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess

M=(1 << 127)-1
BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
ADA_ORIGINAL="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
PY_ORIGINAL="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
BRANCH="qa/issue29-original-witness-bound-v187"
MESSAGE="qa(issue29-v187): correct v186 proof; witness-bound 720-day source-only unreachable weave; zero F"
PATHS={".github/workflows/issue29-v187-source-only-proof.yml",
       "qa/issue29/v187_witness_bound_suffix.py",
       "qa/issue29/V187_WITNESS_BOUND_SUFFIX_PROOF.md"}
SOURCE={
 f"{ADA_ORIGINAL}:src/normative_oracle.adb":"923733d4f8face03586aee304640bf7540c28b4c",
 f"{ADA_ORIGINAL}:src/month_weaving.adb":"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
 f"{PY_ORIGINAL}:tests/normative_reference.py":"d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"}

def require(ok,label):
    if not ok:raise AssertionError(label)

def git(*args):
    return subprocess.check_output(["git",*args],stderr=subprocess.DEVNULL).decode().strip()

def source_guard():
    if not os.environ.get("GITHUB_ACTIONS"):return
    require(os.environ.get("GITHUB_EVENT_NAME")=="push","push only")
    require(os.environ.get("GITHUB_RUN_ATTEMPT")=="1","no rerun")
    require(os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"branch")
    head=git("rev-parse","HEAD")
    require(head==os.environ.get("GITHUB_SHA"),"sha pin")
    event=json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    require(event.get("head_commit",{}).get("message")==MESSAGE,"activation")
    require(subprocess.run(["git","merge-base","--is-ancestor",BASE,head]).returncode==0,"base")
    changed=git("diff","--name-only",BASE+"...HEAD").splitlines()
    require(len(changed)==3 and set(changed)==PATHS,"QA-only files")
    for path,expect in SOURCE.items():
        require(git("rev-parse",path)==expect,"original source drift: "+path)
    lock=Path(".github/workflows/canonical-names-lock.yml").read_text()
    require(lock.count("    if: "+"$"+"{{ false }}")==42,"date-soak halt")
    require(lock.count("  verify:\n")==1,"verify gate")
    
def ticket(first,step,i,slots,mod=M):
    require(1<=first<=mod and step in (-1,1) and 1<=slots<=mod,"ticket domain")
    a=1+(first-1+step*i)%mod
    lim=(mod//slots)*slots
    if a>lim:a=lim if step==-1 else 1
    return 1+(a-1)%slots

def literal_ticket(first,step,i,slots,mod):
    a=1+(first-1+step*i)%mod
    lim=(mod//slots)*slots
    for _ in range(mod):
        if a<=lim:return 1+(a-1)%slots
        a=1+(a-1+step)%mod
    raise AssertionError("literal cyclic walk did not accept")

def labels_from_tickets(lengths,picks):
    rem=[x-2 for x in lengths]; labels=[]
    for pick in picks:
        for idx,q in enumerate(rem):
            if pick>q:pick-=q
            else:
                rem[idx]-=1;labels.append(idx+1);break
        else:raise AssertionError("ticket missing")
    return labels

def legal(lengths,w):
    if len(w)!=sum(lengths):return False
    count=Counter(w)
    if any(count[j]!=lengths[j-1] for j in range(1,len(lengths)+1)):return False
    first=[w.index(j) for j in range(1,len(lengths)+1)]
    last=[len(w)-1-w[::-1].index(j) for j in range(1,len(lengths)+1)]
    return first==sorted(first) and last==sorted(last)

def proof():
    source_guard()
    # v186's *representative* inverse tickets are NOT uniquely forced.
    k_old=246
    alt=[ticket(82,1,i,k_old-i) for i in range(3)]
    require(alt==[82,83,84],"v186 alternate picks")
    require(labels_from_tickets((84,84,84),alt)==[1,2,2],"v186 same labels")
    # Original output day-in-cutlet=503, and >=6 cutlets of >=42 days.
    bound=503+5*42
    require(bound==713 and (bound+122)//123==6,"witness minimum")
    gaps=(503,42,42,42,42,49)
    require(sum(gaps)==720 and all(42<=q<=963 for q in gaps),"720 geometry")
    # Legally sized 6-month year with a fixed-rail legal word.
    lengths=(120,)*6
    k=sum(lengths)-2*len(lengths)
    require(k==708 and k%2==0,"even interior")
    prefix=(1,)*117+(2,)*117+(3,)*117+(4,)*117+(5,)*118+(6,)*118
    tail=(1,3,4,2)
    w=tuple(range(1,7))+prefix+tail+tuple(range(1,7))
    require(len(prefix)==704 and legal(lengths,w),"full-year legal word")
    rem=[118]*6
    for label in prefix:
        require(rem[label-1]>0,"prefix multiplicity")
        rem[label-1]-=1
    require(rem==[1,1,1,1,0,0],"forced suffix state")
    forced=[]
    for label in tail:
        require(rem[label-1]==1,"unique suffix ticket")
        forced.append(1+sum(rem[:label-1]))
        rem[label-1]-=1
    require(forced==[1,2,2,1],"forced ticket values")
    # For 2K+1<=x<=M-2K, no wrap/rejection for any of the first
    # K answers: ticket_i-1=(x-1+d*K) mod (K-i).
    # Slots 4 and 2 are even. Their ticket parities must agree, but
    # the forced tickets 1 and 2 have opposite parity.
    require(M>4*k and forced[0]%2!=forced[2]%2,"safe interval theorem")
    # Exhaust ALL excluded first answers, BOTH directions.
    boundaries=list(range(1,2*k+1))+list(range(M-2*k+1,M+1))
    require(len(boundaries)==4*k,"boundary width")
    exceptions=[]
    for direction in (-1,1):
        for first in boundaries:
            if ticket(first,direction,k-4,4)==1 and ticket(first,direction,k-2,2)==2:
                exceptions.append((first,direction,ticket(first,direction,0,k)))
    require(len(exceptions)==2 and
            sorted(q[2] for q in exceptions)==[635,705],"full edge exhaustiveness")
    # The target starts with interior month 1; at time 0 it has 118
    # copies, so its initial ticket must be in [1,118].
    require(all(q[2]>118 for q in exceptions),"all edges violate first symbol")
    checks=0
    for first in range(1,258):
        for direction in (-1,1):
            for i in range(6):
                require(ticket(first,direction,i,6-i,257)==
                        literal_ticket(first,direction,i,6-i,257),"literal walk")
                checks+=1
    require(checks==3084,"independent finite controls")
    return {
      "schema":"PC_ISSUE29_SOURCE_ONLY_WITNESS_BOUND_SUFFIX_V187/1",
      "old_v186_claim":"RETRACTED_UNPROVEN_EARLY_TICKETS_NON_UNIQUE",
      "v186_alternative_tickets":alt,
      "v186_alternative_same_interior_labels":[1,2,2],
      "witness_observed_day_in_cutlet":503,
      "witness_minimum_year_days":bound,
      "witness_minimum_months":6,
      "witness_minimum_year_offset0":502,
      "synthetic_feasible_gate_gaps":list(gaps),
      "new_legal_month_lengths":list(lengths),
      "new_legal_year_days":len(w),
      "new_legal_full_word_sha256":sha256(bytes(w)).hexdigest(),
      "new_forced_suffix_labels":list(tail),
      "new_forced_suffix_tickets":forced,
      "safe_region_parity_contradiction":True,
      "boundary_streams_checked":len(boundaries)*2,
      "boundary_exceptions":[{"first":str(x),"step":d,"ticket0":t}
                             for x,d,t in exceptions],
      "boundary_exceptions_all_excluded":True,
      "small_modulus_independent_literal_walk_checks":checks,
      "result":"PROVEN_720_DAY_LEGAL_FIXED_RAIL_WEAVE_NOT_REACHABLE_BY_ADA_TICKET_STREAM",
      "historical_30_vs_20_caused_by_this":"UNKNOWN",
      "original_calendar_F_calls":0,
      "native_converter_runs":0,
      "soak_years_certified":0
    }

if __name__=="__main__":
    print(json.dumps(proof(),sort_keys=True,indent=2)+"")
