#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Test-only Befunge-98 computed '_' comparator before the validated w path.

13 exact source-cell edits on the frozen w candidate. A real computed 0/1
operand drives '_' to WEST/EAST executable 2D corridors that independently
reconstruct the old three-item stack and resume the same live w/p/g/j logic.
Expected numbers are from THREE native Befunge references, not Python math.
No QA src promotion, no final Stage 1 acceptance.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys
import stage1_native_diverse_geometry as suite
import stage1_native_reflective_candidate_domain_matrix as domain

FROZEN="qa/interleaved_work_counts_w_data_branch_candidate.b98"
FROZEN_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
PRODUCTION="qa/interleaved_work_counts_pre_two_valid_w_production.b98"
PRODUCTION_BLOB="8f2cf8afef61818244747582fe7c20a74ee18943"
OUT="/underscore"
SOURCE=OUT+"/underscore_w_candidate.b98"
MUTANT=OUT+"/underscore_removed.b98"
COMP=(951,1334)
RESTORE=(951,1333)
W=(951,1332)
LOWER={"foundation_cross","mixed_small","negative_positive",
       "invalid_zero_sign","foundation_neighbor_forward",
       "foundation_neighbor_reverse"}
EAST="invalid_big_sign"

def require(flag,msg):
    if not flag: raise AssertionError(msg)

def gitblob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def source():
    original=open(FROZEN,"rb").read()
    require(gitblob(original)==FROZEN_BLOB,"Native w candidate changed")
    require(gitblob(open(PRODUCTION,"rb").read())==PRODUCTION_BLOB,
            "frozen prior QA reflective source changed; oracle comparison scope shifted")
    rows=original.split("\n")
    require(len(rows)==2016 and max(map(len,rows))==1531,
            "unapproved native source extent")
    # WEST branch for a nonzero computed value:
    # from x950 to x943, 1:0801-x -> stack [1,1,0],
    # x at (943,1334) moves (8,-1) to the ^ bridge (951,1333).
    changes={(951,1334):(":","_"),
             (951,1333):("0","^"),
             (953,1334):("+",":"),
             (955,1334):("1","^"),
             (955,1333):(" ","<")}
    for offset,ch in enumerate("1:0801-x"):
        changes[(950-offset,1334)]=(" ",ch)
    require(len(changes)==13,"incorrect exact patch size")
    for (x,y),(old,new) in changes.items():
        require(rows[y][x]==old,
                "occupied source-map underscore position "+repr((x,y,old,rows[y][x])))
        rows[y]=rows[y][:x]+new+rows[y][x+1:]
    candidate="\n".join(rows)
    require(len(candidate)==len(original) and
            [len(z) for z in rows]==[len(z) for z in original.split("\n")],
            "source row geometry moved")
    with open(SOURCE,"wb") as dest:dest.write(candidate)
    y=COMP[1];x=COMP[0]
    rows[y]=rows[y][:x]+" "+rows[y][x+1:]
    altered="\n".join(rows)
    require(len(altered)==len(candidate) and
            sum(x!=y for x,y in zip(altered,candidate))==1,
            "Native underscore mutant changed more than one byte")
    with open(MUTANT,"wb") as dest:dest.write(altered)
    print("NATIVE_COMBINED_UNDERSCORE_13_CELL_PATCH_PASS",
          hashlib.sha256(candidate).hexdigest())
    return candidate

def trace_route(filename,label):
    comparator=None
    next_event=None
    rejoin=None
    native_w=None
    awaiting=False
    visits={}
    with open(filename,"rb") as stream:
        for line in stream:
            if not line.startswith("STEP\t"):continue
            v=line.rstrip("\n").split("\t")
            require(len(v)==9,"malformed interpreter native STEP")
            event=tuple(map(int,v[1:]))
            tick,ip,x,y,dx,dy,opcode,depth=event
            loc=(x,y)
            if awaiting:
                next_event=event;awaiting=False
            if loc==COMP:
                require(comparator is None,"underscore Native IP loop/reentry")
                comparator=event;awaiting=True
            if loc==RESTORE:
                require(rejoin is None,"Native underscore rejoined twice")
                rejoin=event
            if loc==W:
                require(native_w is None,"Native w executed twice")
                native_w=event
            if loc in ((943,1334),(955,1333)):
                visits[loc]=visits.get(loc,0)+1
    if label in LOWER:
        require(comparator is None and rejoin is None and native_w is None,
                "lower Native arithmetic erroneously entered underscore")
        return "lower",None
    require(comparator and next_event and rejoin and native_w,
            "upper computed comparator or rejoin missing "+label)
    require(comparator[4:8]==(0,-1,ord("_"),1),
            "Native underscore not executed on the 0/1 operand")
    mode="east" if label==EAST else "west"
    dest=(952,1334) if mode=="east" else (950,1334)
    require(next_event[2:4]==dest and
            next_event[0]==comparator[0]+1,
            "Native actual underscore did not choose required direction "+label)
    heading=(-1,0) if mode=="east" else (8,-1)
    require(rejoin[4:8]==(heading[0],heading[1],ord("^"),3),
            "2D comparator branch failed to restore three arithmetic values "+label)
    require(native_w[0]==rejoin[0]+1 and native_w[4:8]==(0,-1,ord("w"),3),
            "Native w was not reentered with original stack and heading "+label)
    require(visits.get((943,1334),0)==(1 if mode=="west" else 0)
            and visits.get((955,1333),0)==(1 if mode=="east" else 0),
            "unselected Native computed arm was executed "+label)
    return "upper",mode

def bounded(path,raw):
    p=subprocess.Popen(["timeout","--kill-after=2s","8s"]+
                       suite.COMMAND+[path],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    return p.returncode,out.split(),err[-500:]

def main():
    require(os.path.isdir(OUT),"missing Native underscore QA trace directory")
    revised=source()
    results=[]
    modes=set()
    causal=None
    for label,fields,valid in suite.CASES:
        raw=" ".join(map(str,fields))+"\n"
        oracle=suite.expected_for(*fields) if valid else ["-1"]*7
        prior=suite.native(PRODUCTION,raw)
        filename=OUT+"/"+label+".tsv"
        current=suite.native(SOURCE,raw,trace=filename)
        require(len(oracle)==len(prior)==len(current)==7 and
                oracle==prior==current,
                "Native source/underscore/reference arithmetic diverged "+label)
        arm,mode=trace_route(filename,label)
        if mode:
            modes.add(mode)
            if mode=="west" and valid and causal is None:
                causal=(label,raw,oracle)
        results.append({"case":label,"valid":valid,"branch":arm,"mode":mode,
                        "trace_sha256":hashlib.sha256(open(filename,"rb").read()).hexdigest()})
        print("NATIVE_UNDERSCORE_W_REAL_2D_ORACLE_PASS",label,arm,mode)
        sys.stdout.flush()
    require(len(results)==17 and modes=={"east","west"} and causal,
            "Native computed underscore did not exercise both outcome branches")
    wide=[]
    for label,fields,valid in domain.CASES:
        raw=" ".join(map(str,fields))+"\n"
        oracle=suite.expected_for(*fields) if valid else ["-1"]*7
        prior=suite.native(PRODUCTION,raw)
        now=suite.native(SOURCE,raw)
        require(len(oracle)==len(prior)==len(now)==7 and
                oracle==prior==now,
                "wider domain underscores changed Befunge arithmetic "+label)
        wide.append({"case":label,"valid":valid})
        print("NATIVE_UNDERSCORE_EXTENDED_DOMAIN_PASS",label)
        sys.stdout.flush()
    name,raw,oracle=causal
    exitcode,mutant,err=bounded(MUTANT,raw)
    require(exitcode!=0 or mutant!=oracle,
            "single-byte removal of executed underscore had no observable effect")
    report={"schema":"befunge-stage1-native-underscore-w-v1",
            "status":"QA_TEST_ONLY_UNPROMOTED",
            "source_sha256":hashlib.sha256(revised).hexdigest(),
            "source_exact_edit_count":13,"cases":results,
            "wide_native_cases":len(wide),
            "observed_comparator_outcomes":sorted(modes),
            "mutant":{"case":name,"exit":exitcode,
                      "numerical_change":mutant!=oracle}}
    with open(OUT+"/underscore_w_qa_proof.json","wb") as fp:
        fp.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_UNDERSCORE_AND_W_QA_CANDIDATE_PASS",
          len(results),"real traces",len(wide),"boundary differentials")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; only test candidate")

if __name__=="__main__":
    main()
