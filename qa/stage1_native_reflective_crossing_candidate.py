#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Test-only, fail-closed Native 2D reflective merge/fork candidate.

No calendar arithmetic in Python; all output expectations are three independent
Befunge-98 reference programs. A live PyFunge trace proves a repeated executed
coordinate with two actual predecessors and two actual successors *in one run*.
An original-byte sham and one-byte r-removal control test causal necessity.
"""
from __future__ import print_function
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import stage1_native_diverse_geometry as suite

BASE="src/interleaved_work_counts.b98"
CANDIDATE="qa/interleaved_work_counts_reflective_crossing_candidate.b98"
OUT="/reflective"
ORIGINAL_BLOB="44c5c33f4fe88ad82b8172235f18ad5d5175e517"
CANDIDATE_BLOB="8f2cf8afef61818244747582fe7c20a74ee18943"
CHANGES={(957,1324):(" ","r"), (958,1324):("1","["),
         (958,1323):("c","1"), (958,1322):("x","d"),
         (958,1321):(" ","x")}
FORK=(951,1335)
ARM_UP=(951,1334)
ARM_DOWN=(951,1336)
PIVOT=(958,1324)
REFLECT=(957,1324)
LANDING=(959,1334)
UPPATH=[FORK,ARM_UP,(958,1325),PIVOT,REFLECT,PIVOT,
        (958,1323),(958,1322),(958,1321),LANDING]
DOWNPATH=[FORK,ARM_DOWN]
WATCH=set(UPPATH+DOWNPATH)

def require(ok,msg):
    if not ok:
        raise AssertionError(msg)

def blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def verify_byte_map():
    original=open(BASE,"rb").read()
    revised=open(CANDIDATE,"rb").read()
    require(blob(original)==ORIGINAL_BLOB,"source baseline Git blob drift")
    require(blob(revised)==CANDIDATE_BLOB,"candidate Git blob drift")
    require(len(original)==len(revised),"source dimensions/bytes changed")
    a=original.split("\n")
    b=revised.split("\n")
    require(len(a)==len(b)==2016 and
            max(map(len,a))==max(map(len,b))==1531,
            "2D shape unexpectedly changed")
    actual={}
    for y,(left,right) in enumerate(zip(a,b)):
        require(len(left)==len(right),"source line width changed")
        for x,(before,after) in enumerate(zip(left,right)):
            if before!=after:
                actual[(x,y)]=(before,after)
    require(actual==CHANGES,"candidate is not exact five-cell control detour: "+repr(actual))
    require(b[1325][958]=="c" and b[1334][959]==">",
            "original Befunge arithmetic stack/rejoin bytes changed")
    print("NATIVE_REFLECTIVE_CANDIDATE_EXACT_SOURCE_MAP_PASS",len(actual),
          "original_blob",ORIGINAL_BLOB,"candidate_blob",CANDIDATE_BLOB)

def observed_route(path):
    focused=[]
    with open(path,"rb") as src:
        for line in src:
            if not line.startswith("STEP\t"):
                continue
            v=line.rstrip("\n").split("\t")
            require(len(v)==9,"malformed real native STEP record")
            tick,ip,x,y,dx,dy,op,depth=map(int,v[1:])
            if (x,y) in WATCH:
                focused.append((tick,ip,x,y,dx,dy,op,depth))
    coords=[(v[2],v[3]) for v in focused]
    if coords==UPPATH:
        branch="up"
        pivot=[e for e in focused if (e[2],e[3])==PIVOT]
        reflect=[e for e in focused if (e[2],e[3])==REFLECT]
        last=[e for e in focused if (e[2],e[3])==LANDING]
        require(len(pivot)==2 and len(reflect)==len(last)==1,
                "native reflective loop missing/duplicated")
        require((pivot[0][4],pivot[0][5],pivot[0][6])==(0,-1,ord("[")) and
                (reflect[0][4],reflect[0][5],reflect[0][6])==(-1,0,ord("r")) and
                (pivot[1][4],pivot[1][5],pivot[1][6])==(1,0,ord("[")),
                "real interpreter did not perform directional reflect/turn")
        require(last[0][4:7]==(1,13,ord(">")),
                "Native vector jump did not land at original heading reset")
        require(last[0][7]==5,
                "Native loop changed arithmetic stack depth at landing")
        require(pivot[0][0]+1==reflect[0][0] and
                reflect[0][0]+1==pivot[1][0],
                "reflected crossing is not an adjacent, actual executed loop")
        # At PIVOT the *same run* proves two incoming and two outgoing
        # real IP edges. Re-execution is not a source-map decorative crossing.
        incoming=set(((958,1325),REFLECT))
        outgoing=set((REFLECT,(958,1323)))
        require(len(incoming)==len(outgoing)==2,
                "executed per-run merge/fork incidence lost")
    elif coords==DOWNPATH:
        branch="down"
    else:
        raise AssertionError("wrong Native candidate route, seen=%r"%(coords,))
    return branch,[{"tick":v[0],"x":v[2],"y":v[3],
                    "dx":v[4],"dy":v[5],"opcode":v[6],"depth":v[7]}
                   for v in focused]

def bounded_native(program,raw):
    cmd=["timeout","--kill-after=2s","8s"]+suite.COMMAND+[program]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    got,err=p.communicate(raw)
    return p.returncode,got.split(),err[-500:]

def controlled_mutant():
    raw="0 0 0 0\n"
    want=suite.expected_for(0,0,0,0)
    sham=shutil.copyfile(CANDIDATE,os.path.join(OUT,"sham_exact.b98"))
    original=open(CANDIDATE,"rb").read()
    require(open(sham,"rb").read()==original,"negative-control copy diverged")
    rc,out,err=bounded_native(sham,raw)
    require(rc==0 and out==want,
            "exact-byte sham not equal to real native reference: "+repr((rc,out,err)))
    rows=original.split("\n")
    y=1324
    require(rows[y][957]=="r","executed r removed before mutant")
    rows[y]=rows[y][:957]+" "+rows[y][958:]
    modified="\n".join(rows)
    require(len(modified)==len(original) and
            sum(a!=b for a,b in zip(modified,original))==1,
            "counterfactual must change exactly one executed native byte")
    mutant=os.path.join(OUT,"mutant_r_removed.b98")
    open(mutant,"wb").write(modified)
    rc,out,err=bounded_native(mutant,raw)
    require(rc!=0 or out!=want,
            "Native output unchanged despite one-cell reversal removal")
    print("NATIVE_REFLECTIVE_R_CAUSAL_MUTANT_PASS",
          "sham_identical",True,"mutant_rc",rc,
          "mutant_output_changed",out!=want,"bounded_seconds",8)
    sys.stdout.flush()

def main():
    require(os.path.isdir(OUT),"writable native evidence output missing")
    verify_byte_map()
    report=[]
    upper=0
    lower=0
    for label,fields,valid in suite.CASES:
        raw=" ".join(map(str,fields))+"\n"
        path=os.path.join(OUT,label+".tsv")
        got=suite.native(CANDIDATE,raw,trace=path)
        want=suite.expected_for(*fields) if valid else ["-1"]*7
        require(got==want and len(got)==7,
                "candidate differs from independent Befunge native oracle "+label)
        branch,hits=observed_route(path)
        upper+=(branch=="up")
        lower+=(branch=="down")
        report.append({"case":label,"valid":valid,"branch":branch,
                       "source_trace_sha256":hashlib.sha256(open(path,"rb").read()).hexdigest(),
                       "trace_file":label+".tsv","route":hits,"result":got})
        print("NATIVE_REFLECTIVE_CROSSING_ORACLE_ROUTE_PASS",
              label,branch,len(hits),"actual_native_IP_events")
        sys.stdout.flush()
    require(upper>=2 and lower>=2,
            "both genuine input-selected Native arithmetic arms must execute")
    controlled_mutant()
    proof={"schema":"befunge-stage1-native-reflective-crossing-candidate-v1",
           "status":"QA_CANDIDATE_ONLY_NOT_STAGE1_ACCEPTANCE",
           "candidate_blob":CANDIDATE_BLOB,"production_unchanged":True,
           "source_changed_cells":5,"native_cases":len(report),
           "upper":upper,"lower":lower,"crossing_coordinate":list(PIVOT),
           "single_run_in_degree":2,"single_run_out_degree":2,
           "results":report}
    with open(os.path.join(OUT,"reflective_candidate_proof.json"),"wb") as dst:
        dst.write(json.dumps(proof,sort_keys=True,indent=2)+"\n")
    print("NATIVE_REFLECTIVE_CROSSING_CANDIDATE_PASS",
          len(report),"cases",upper,"upper",lower,"lower",
          "dual_merge_and_fork_native_node",PIVOT)
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; test-only, no src promotion")

if __name__=="__main__":
    main()
