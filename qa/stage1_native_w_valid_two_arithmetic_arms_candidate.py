#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real PyFunge-98 candidate: both VALID signed-date arms through one w.

Python does not compute the calendar. Expectations come from three
independent Native Befunge references; the prior w program is also run.
Native STEP events must show upper/right and lower/straight, and *exact*
post-rejoin instruction, heading and stack depths against prior program.
No promotion, no implicit Stage 1 acceptance.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys
import stage1_native_diverse_geometry as n
import stage1_native_reflective_candidate_domain_matrix as domain

BASE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
CAND="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
BASE_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
CAND_BLOB="1cf3ffa0466ea33465bf8acc632a3d10fa568587"
OUT="/validw"
LOWER=frozenset(("foundation_cross","mixed_small","negative_positive",
    "invalid_zero_sign","foundation_neighbor_forward",
    "foundation_neighbor_reverse"))
U=(953,1332)
L=(952,1336)
W=(951,1332)
TURN=(951,1336)
def must(ok,why):
    if not ok:raise AssertionError(why)
def blob(b):return hashlib.sha1("blob %d\0%s"%(len(b),b)).hexdigest()

def static_proof():
    a=open(BASE,"rb").read();b=open(CAND,"rb").read()
    must(blob(a)==BASE_BLOB and blob(b)==CAND_BLOB,"source Git blob mismatch")
    aa=a.split("\n");bb=b.split("\n")
    must(len(aa)==len(bb)==2016 and len(a)==len(b)
         and [len(x) for x in aa]==[len(x) for x in bb]
         and max(map(len,bb))==1531,"2D source dimensions changed")
    changes={}
    for y,(before,after) in enumerate(zip(aa,bb)):
        for x,(old,new) in enumerate(zip(before,after)):
            if old!=new:changes[(x,y)]=(old,new)
    expected={(951,1334):(":","0"),(951,1333):("0","^"),
        (951,1336):("[","]"),(951,1337):(" ","^"),
        (950,1336):(" ","0"),(949,1336):(" ","8"),
        (948,1336):(" ","0"),(947,1336):(" ","3"),
        (946,1336):(" ","-"),(943,1336):(" ","x")}
    for i,(a,b) in enumerate(zip("$001-#","006-6x")):
        if a!=b:expected[(952+i,1331)]=(a,b)
    must(changes==expected,"changed extra or wrong Native source cells "+repr(changes))
    print("NATIVE_TWO_VALID_W_EXACT_SOURCE_MAP_PASS",len(changes),
          "candidate",CAND_BLOB)

def events(path):
    result=[]
    with open(path,"rb") as f:
        for line in f:
            if not line.startswith("STEP\t"):continue
            p=line.rstrip("\n").split("\t")
            must(len(p)==9,"invalid native event")
            result.append(tuple(map(int,p[1:])))
    must(len(result)>=7000,"Native IP trace too small")
    return result

def sig(rest):
    return [tuple(x[2:]) for x in rest]

def suffix(trace,p):
    i=next((i for i,z in enumerate(trace) if z[2:4]==p),None)
    must(i is not None,"missing post-rejoin Native trace")
    return sig(trace[i:])

def inspect(trace,upper):
    at=[i for i,e in enumerate(trace) if e[2:4]==W]
    must(len(at)==1,"real Native w did not execute once")
    t=at[0];event=trace[t]
    must(event[4:8]==(0,-1,ord("w"),2),"Native w input/heading/stack invalid")
    expected=(952,1332) if upper else (951,1331)
    must(trace[t+1][2:4]==expected,
         "actual w successor not input-selected on valid/invalid branch")
    visits=[i for i,e in enumerate(trace) if e[2:4]==TURN]
    if upper:
        must(not visits,"upper path contaminated lower arithmetic")
    else:
        must(len(visits)==2 and visits[0]<t<visits[1],
             "lower Native route did not visit shared directional cell twice")
        must(trace[visits[0]][4:7]==(0,1,ord("]"))
             and trace[visits[1]][4:7]==(0,-1,ord("]")),
             "Native lower 2D turnaround lost opposite headings")
        must(trace[visits[0]+1][2:4]==(950,1336)
             and trace[visits[1]+1][2:4]==L,
             "Native lower turns were not west then east")
        must(trace[visits[1]+1][4:8]==(1,0,ord("1"),1),
             "Native lower rejoin stack not preserved")
    return "right" if upper else "straight"

def bound(path,input):
    p=subprocess.Popen(["timeout","--kill-after=2s","8s"]+
                       n.COMMAND+[path],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(input)
    return p.returncode,out.split()

def main():
    must(os.path.isdir(OUT),"Native artifacts volume missing")
    static_proof()
    reports=[]
    valid_modes=set()
    for label,fields,valid in n.CASES:
        raw=" ".join(map(str,fields))+"\n"
        expected=n.expected_for(*fields) if valid else ["-1"]*7
        oldfile=OUT+"/"+label+".old.tsv"
        newfile=OUT+"/"+label+".new.tsv"
        a=n.native(BASE,raw,trace=oldfile)
        b=n.native(CAND,raw,trace=newfile)
        must(a==b==expected and len(b)==7,
             "Native oracle differential changed "+label)
        upper=label not in LOWER
        oldsteps=events(oldfile);newsteps=events(newfile)
        mode=inspect(newsteps,upper)
        join=U if upper else L
        must(suffix(oldsteps,join)==suffix(newsteps,join),
             "native post-rejoin arithmetic IP/depth/heading differs "+label)
        if valid:valid_modes.add(mode)
        reports.append({"case":label,"valid":valid,"mode":mode,
                        "trace":label+".new.tsv",
                        "sha256":hashlib.sha256(open(newfile,"rb").read()).hexdigest()})
        print("NATIVE_W_TWO_VALID_COMPUTED_BRANCH_PASS",label,mode,
              "valid",valid);sys.stdout.flush()
    must(valid_modes==set(("right","straight")),
         "both computed w outcomes must occur on VALID inputs")
    for label,fields,valid in domain.CASES:
        raw=" ".join(map(str,fields))+"\n"
        expected=n.expected_for(*fields) if valid else ["-1"]*7
        a=n.native(BASE,raw);b=n.native(CAND,raw)
        must(a==b==expected and len(b)==7,
             "22-case Native boundary parity failed "+label)
        print("NATIVE_W_TWO_VALID_WIDE_ORACLE_PASS",label)
        sys.stdout.flush()
    data=open(CAND,"rb").read();r=data.split("\n")
    must(r[1332][951]=="w","Native w byte missing")
    r[1332]=r[1332][:951]+" "+r[1332][952:]
    mutant="\n".join(r)
    must(len(data)==len(mutant) and
         sum(a!=b for a,b in zip(data,mutant))==1,
         "causal mutant changed more than one source byte")
    mp=OUT+"/w_removed.b98";open(mp,"wb").write(mutant)
    counter=[]
    for name,fields in (("upper",(0,0,0,0)),
                        ("lower",(1,15055672,1,15055670))):
        want=n.expected_for(*fields)
        rc,got=bound(mp," ".join(map(str,fields))+"\n")
        must(rc!=0 or got!=want,
             "Native w single-byte mutant has no effect on valid "+name)
        counter.append({"name":name,"rc":rc,"changed_output":got!=want})
        print("NATIVE_TWO_VALID_W_ONE_BYTE_MUTANT_PASS",name,
              "rc",rc,"changed_output",got!=want)
    proof={"schema":"stage1-native-w-two-valid-arms-v1",
       "scope":"QA_ONLY_NOT_PROMOTED", "candidate_git_blob":CAND_BLOB,
       "changed_source_cells":15,"both_valid_branches_executed":True,
       "cases":reports,"wide_case_count":len(domain.CASES),
       "causal_mutants":counter}
    with open(OUT+"/native_valid_w_two_arm_proof.json","wb") as f:
        f.write(json.dumps(proof,indent=2,sort_keys=True)+"\n")
    print("NATIVE_W_TWO_VALID_INPUT_OUTCOMES_QA_PASS",len(reports),
          "traces",len(domain.CASES),"additional Native boundary cases")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; candidate not production")
if __name__=="__main__":main()
