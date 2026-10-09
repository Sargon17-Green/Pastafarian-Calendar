#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Funge98 shared VALID w comparison plus invalid upper '_' sentry.

Only PyFunge runs arithmetic and the independent Native Befunge reference.
The 2D source has 18 audited cell edits, a real two-in/out lower
junction, signed upper/lower true-valid w outcomes, and preserved original
IP/opcode/heading/stack suffixes after returning from new computed lanes.
This is an unpromoted test-only candidate and NOT Stage 1 acceptance.
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
CAND_BLOB="b6cf50de9ed45376db5fc4ebd003157210dff03b"
OUT="/validw"
LOWER=frozenset(("foundation_cross","mixed_small","negative_positive",
    "invalid_zero_sign","foundation_neighbor_forward",
    "foundation_neighbor_reverse"))
INVALID_UPPER="invalid_big_sign"
W=(951,1332)
SENTRY=(951,1331)
TURN=(951,1336)
UPPER_CONT=(953,1332)
INVALID_CONT=(958,1334)
LOWER_CONT=(952,1336)

def require(cond,msg):
    if not cond:raise AssertionError(msg)
def blob(buf):
    return hashlib.sha1("blob %d\0%s"%(len(buf),buf)).hexdigest()

def source_guard():
    src=open(BASE,"rb").read();dst=open(CAND,"rb").read()
    require(blob(src)==BASE_BLOB and blob(dst)==CAND_BLOB,
            "Native frozen source blob drift")
    a=src.split("\n");b=dst.split("\n")
    require(len(a)==len(b)==2016 and len(src)==len(dst)
            and max(map(len,b))==1531
            and [len(x) for x in a]==[len(x) for x in b],
            "Native Funge-space shape or line widths changed")
    expected={(951,1334):(":","0"),(951,1333):("0","^"),
        (951,1331):(">","_"),(951,1336):("[","]"),
        (951,1337):(" ","^")}
    for i,c in enumerate("$100903-x"):
        expected[(950-i,1336)]=(" ",c)
    for x,c in ((950,"0"),(949,"8"),(948,"6"),(943,"x")):
        expected[(x,1331)]=(" ",c)
    changed={}
    for y,(old,new) in enumerate(zip(a,b)):
        for x,(first,last) in enumerate(zip(old,new)):
            if first!=last:changed[(x,y)]=(first,last)
    require(changed==expected and len(changed)==18,
            "Native 18-cell planned source map diverged "+repr(changed))
    require(b[1332][951]=="w" and b[1331][951]=="_",
            "computed source lost real w/_ corridor")
    print("NATIVE_TWO_VALID_W_UNDERSCORE_EXACT_SOURCE_PASS",len(changed),
          CAND_BLOB)

def steps(path):
    result=[]
    with open(path,"rb") as fp:
        for l in fp:
            if l.startswith("STEP\t"):
                x=l.rstrip("\n").split("\t")
                require(len(x)==9,"bad real Native STEP")
                result.append(tuple(map(int,x[1:])))
    require(len(result)>=7000,"no full Native trace")
    return result

def postfix(trace,point):
    i=next((j for j,e in enumerate(trace) if e[2:4]==point),None)
    require(i is not None,"native arithmetic rejoin missing "+repr(point))
    return [e[2:] for e in trace[i:]]

def trace_route(trace,label):
    lower=label in LOWER; invalid=label==INVALID_UPPER
    wpos=[i for i,e in enumerate(trace) if e[2:4]==W]
    require(len(wpos)==1,"must execute one real w on every arithmetic case")
    i=wpos[0]
    entry=trace[i];next_step=trace[i+1]
    require(entry[4:7]==(0,-1,ord("w")) and
            entry[7]==(3 if lower else 2),
            "native comparator operands/depth or inbound vector not as designed")
    w_mode="straight" if lower or invalid else "right"
    next_xy=(951,1331) if w_mode=="straight" else (952,1332)
    require(next_step[2:4]==next_xy and next_step[0]==entry[0]+1,
            "actual native w path ignored computed input")
    sentries=[i for i,e in enumerate(trace) if e[2:4]==SENTRY]
    require(len(sentries)==(1 if w_mode=="straight" else 0),
            "Native semantic '_' sentinel missing/unexpected")
    if sentries:
        x=sentries[0];node=trace[x];following=trace[x+1]
        require(node[6]==ord("_") and node[4:6]==(0,-1),
                "native underscore not executed with north-bound IP")
        require(following[2:4]==((950,1331) if lower else (952,1331)),
                "Native underscore did not distinguish lower-VALID vs upper-invalid")
    v=[position for position,e in enumerate(trace) if e[2:4]==TURN]
    if lower:
        require(len(v)==2 and v[0]<wpos[0]<v[1],
                "real lower same-cell two-entry geometry not executed")
        require(trace[v[0]][4:7]==(0,1,ord("]"))
                and trace[v[1]][4:7]==(0,-1,ord("]"))
                and trace[v[0]+1][2:4]==(950,1336)
                and trace[v[1]+1][2:4]==LOWER_CONT,
                "Native lower dual node does not change directions twice")
        require(trace[v[1]+1][4:8]==(1,0,ord("1"),1),
                "Native lower resume stack/direction altered")
    else:
        require(not v,"upper route entered unselected lower geometry")
    return ("lower" if lower else "invalid" if invalid else "upper"),w_mode

def run_mutant(path,raw):
    p=subprocess.Popen(["timeout","--kill-after=2s","8s"]+
        n.COMMAND+[path],stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    return p.returncode,out.split()

def main():
    require(os.path.isdir(OUT),"Native evidence volume missing")
    source_guard()
    proof=[];valid_w=set()
    for label,fields,valid in n.CASES:
        raw=" ".join(map(str,fields))+"\n"
        expected=n.expected_for(*fields) if valid else ["-1"]*7
        ap=OUT+"/"+label+".old.tsv";bp=OUT+"/"+label+".new.tsv"
        before=n.native(BASE,raw,trace=ap)
        after=n.native(CAND,raw,trace=bp)
        require(before==after==expected and len(after)==7,
                "Native Befunge-only 7-field oracle mismatch "+label)
        oldtrace=steps(ap);newtrace=steps(bp)
        group,route=trace_route(newtrace,label)
        continue_at=(LOWER_CONT if group=="lower" else
                     INVALID_CONT if group=="invalid" else UPPER_CONT)
        require(postfix(oldtrace,continue_at)==postfix(newtrace,continue_at),
                "Native post-rejoin executed instructions/depth differ "+label)
        if valid:valid_w.add(route)
        proof.append({"case":label,"valid":valid,"group":group,"mode":route,
                      "trace":label+".new.tsv",
                      "trace_sha256":hashlib.sha256(open(bp,"rb").read()).hexdigest()})
        print("NATIVE_TWO_VALID_W_BRANCH_NATIVE_ORACLE_PASS",label,group,route)
        sys.stdout.flush()
    require(valid_w=={"straight","right"},"VALID Native cases did not exercise both w outcomes")
    for label,fields,valid in domain.CASES:
        raw=" ".join(map(str,fields))+"\n"
        oracle=n.expected_for(*fields) if valid else ["-1"]*7
        old=n.native(BASE,raw);new=n.native(CAND,raw)
        require(old==new==oracle and len(new)==7,
                "extended signed-domain Native parity failed "+label)
        print("NATIVE_TWO_VALID_W_WIDE_SIGNED_DOMAIN_PASS",label)
        sys.stdout.flush()
    data=open(CAND,"rb").read()
    lines=data.split("\n");require(lines[1332][951]=="w","mutant W missing")
    lines[1332]=lines[1332][:951]+" "+lines[1332][952:]
    revised="\n".join(lines)
    require(len(revised)==len(data) and
            sum(a!=b for a,b in zip(data,revised))==1,
            "Native counterfactual modified extra bytes")
    mutant=OUT+"/single_w_removed.b98";open(mutant,"wb").write(revised)
    controls=[]
    for label,fields in (("valid_upper",(0,0,0,0)),
                         ("valid_lower",(1,15055672,1,15055670))):
        want=n.expected_for(*fields)
        rc,got=run_mutant(mutant," ".join(map(str,fields))+"\n")
        require(rc!=0 or got!=want,
                "single-byte w removal had no effect on VALID "+label)
        controls.append({"case":label,"exit":rc,"output_changed":got!=want})
        print("NATIVE_TWO_VALID_W_SINGLE_BYTE_COUNTERFACTUAL_PASS",
              label,"exit",rc,"result_different",got!=want)
    evidence={"schema":"befunge-stage1-two-valid-w-native-v2",
        "status":"QA_EXPERIMENT_ONLY_NOT_PROMOTED",
        "candidate_blob":CAND_BLOB,"source_exact_changed_cells":18,
        "two_valid_w_comparison_outcomes":True,
        "cases":proof,"wide_oracle_cases":len(domain.CASES),
        "causal_controls":controls}
    with open(OUT+"/native_two_valid_w_evidence.json","wb") as f:
        f.write(json.dumps(evidence,sort_keys=True,indent=2)+"\n")
    print("NATIVE_TWO_VALID_W_AND_SEMANTIC_UNDERSCORE_CANDIDATE_PASS",
          len(proof),"traces",len(domain.CASES),"wide cases")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; QA experiment only")
if __name__=="__main__":main()
