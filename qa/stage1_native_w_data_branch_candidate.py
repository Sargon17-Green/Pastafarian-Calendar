#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Befunge-98 DATA-DEPENDENT 'w' arithmetic experiment. QA-only.

Generate a precise, test-only source edit atop the SHA-pinned reflective
production. On one real computed branch the actual operand is 0 or 1:
the Native w instruction selects separate 2D arithmetic lanes that REPLACE
that operand with its branch-dependent value and restore -1. Both lanes
rejoin the EXISTING executable '^' / j / g/p continuation by real x vectors.
Removing the executed w must produce an incorrect seven-value result, not
merely a different trace. All expected results come from independent Native
Befunge reference programs, never a Python calendar model.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys

import stage1_native_diverse_geometry as suite
import stage1_native_reflective_candidate_domain_matrix as wide

BASE="qa/interleaved_work_counts_pre_two_valid_w_production.b98"
FROZEN="qa/interleaved_work_counts_w_data_branch_candidate.b98"
FROZEN_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
BASE_BLOB="8f2cf8afef61818244747582fe7c20a74ee18943"
OUT="/wturn"
GATE=(951,1335)
ENTRY=(951,1334)
PUSH=(951,1333)
W=(951,1332)
STRAIGHT=(951,1331)
RIGHT=(952,1332)
REJOIN=(958,1334)
SOURCE_FILE=os.path.join(OUT,"w_data_branch_candidate.b98")
MUTANT_FILE=os.path.join(OUT,"w_removed_counterfactual.b98")
LOWER_LABELS=frozenset(("foundation_cross","mixed_small",
     "negative_positive","invalid_zero_sign",
     "foundation_neighbor_forward","foundation_neighbor_reverse"))

def require(ok,why):
    if not ok:
        raise AssertionError(why)

def blob(data):
    return hashlib.sha1("blob %d\0%s" % (len(data),data)).hexdigest()

def byte_at(rows,x,y):
    return rows[y][x] if x<len(rows[y]) else " "

def candidate_source():
    original=open(BASE,"rb").read()
    require(blob(original)==BASE_BLOB,"promoted Native QA source changed")
    rows=original.split("\n")
    require(len(rows)==2016 and max(map(len,rows))==1531,
            "Native source Funge-space dimensions drifted")
    require(byte_at(rows,951,1334)=="]" and
            rows[1334][952:957]=="0+01-" and
            byte_at(rows,958,1334)=="^" and
            byte_at(rows,958,1332)=="5" and
            byte_at(rows,958,1331)=="j",
            "Native verified fork, arithmetic or j bridge changed")
    edits={(951,1334):("]",":"), (951,1333):(" ","0"),
           (951,1332):(" ","w"), (951,1331):(" ",">")}
    # Each 2D arm is REAL computation: it consumes the original 0/1
    # operand and produces the chosen result plus the required -1 value.
    # If w is removed, a one-input follows the zero arm and becomes wrong.
    for y,start,circuit in [
        (1331,952,"$001-#"), (1331,959,"006-3x"),
        (1332,952,"$101-#"), (1332,959,"006-2x")
    ]:
        for offset,ch in enumerate(circuit):
            edits[(start+offset,y)]=(" ",ch)
    for (x,y),(before,after) in edits.items():
        require(byte_at(rows,x,y)==before,
                "nonempty reserved native w route cell (%d,%d): %r" %
                (x,y,byte_at(rows,x,y)))
        row=rows[y]
        if len(row)<=x:
            row=row+" "*(x+1-len(row))
        rows[y]=row[:x]+after+row[x+1:]
    require(len(rows)==2016 and max(map(len,rows))==1531,
            "test-only control corridor expanded global Funge bounds")
    new="\n".join(rows)
    with open(SOURCE_FILE,"wb") as target:
        target.write(new)
    with open(FROZEN,"rb") as frozen:
        pinned=frozen.read()
    require(blob(pinned)==FROZEN_BLOB and pinned==new and len(edits)==28,
            "committed w candidate differs from generated exact source")
    require(new!=original and byte_at(rows,951,1332)=="w",
            "w candidate did not alter executed source")
    print("NATIVE_W_EXACT_TEST_ONLY_SOURCE_PASS",
          "edits",len(edits),"source_sha256",hashlib.sha256(new).hexdigest())
    return new,edits

def route(trace):
    w=[]
    starts=[]
    joins=[]
    previous=None
    pending_w=False
    with open(trace,"rb") as stream:
        for line in stream:
            if not line.startswith("STEP\t"):
                continue
            tokens=line.rstrip("\n").split("\t")
            require(len(tokens)==9,"bad Native step format")
            event=tuple(map(int,tokens[1:]))
            tick,ip,x,y,dx,dy,op,depth=event
            xy=(x,y)
            if pending_w:
                starts.append(event)
                pending_w=False
            if xy==W:
                w.append(event)
                pending_w=True
            if xy==REJOIN:
                joins.append((previous,event))
            previous=event
    require(not pending_w and len(w)<=1,
            "w candidate missing successor or loops at directional comparator")
    if not w:
        require(not starts and not joins,
                "lower arithmetic branch leaked into upper Native w corridor")
        return "lower",None
    require(len(w)==len(starts)==len(joins)==1,
            "upper w route was not executed exactly once with rejoin")
    node,nxt=w[0],starts[0]
    require((node[4],node[5],node[6],node[7])==(0,-1,ord("w"),3),
            "Native w operands/entry velocity/stack not as designed")
    options={(951,1331):("straight",(-6,3),ord(">")),
             (952,1332):("right",(-6,2),ord("$"))}
    require((nxt[2],nxt[3]) in options,
            "Native w did not choose either data-dependent input lane")
    mode,vector,next_opcode=options[(nxt[2],nxt[3])]
    require(nxt[0]==node[0]+1 and nxt[6]==next_opcode and nxt[7]==1,
            "w did not consume two branch operands before real arithmetic")
    last,joined=joins[0]
    require((last[2],last[3])==(964,1331 if mode=="straight" else 1332)
            and last[6]==ord("x") and last[7]==5 and
            last[0]+1==joined[0],
            "input-selected math lane did not execute its vector transfer")
    require((joined[4],joined[5])==vector and
            joined[6]==ord("^") and joined[7]==3,
            "dynamic Native x failed to rejoin unchanged original arithmetic")
    return "upper",mode

def mutant(data,edits):
    require(edits[W]==(" ","w"),"missing single w opcode in planned edit map")
    rows=data.split("\n")
    require(rows[W[1]][W[0]]=="w","mutant must target executed w")
    rows[W[1]]=rows[W[1]][:W[0]]+" "+rows[W[1]][W[0]+1:]
    modified="\n".join(rows)
    require(len(modified)==len(data) and
            sum(a!=b for a,b in zip(modified,data))==1,
            "causal mutant changed anything beyond the one executed w")
    with open(MUTANT_FILE,"wb") as target:
        target.write(modified)

def call_bounded(source,raw,seconds):
    p=subprocess.Popen(["timeout","--kill-after=2s",str(seconds)+"s"]+
            suite.COMMAND+[source],stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    output,errors=p.communicate(raw)
    return p.returncode,output.split(),errors[-500:]

def main():
    require(os.path.isdir(OUT),"missing QA-only /wturn evidence mount")
    data,edits=candidate_source()
    reports=[]
    modes=set()
    counts={"upper":0,"lower":0}
    right_case=None
    for label,fields,valid in suite.CASES:
        raw=" ".join(map(str,fields))+"\n"
        reference=suite.expected_for(*fields) if valid else ["-1"]*7
        old=suite.native(BASE,raw)
        trace=os.path.join(OUT,label+".tsv")
        actual=suite.native(SOURCE_FILE,raw,trace=trace)
        require(len(reference)==len(old)==len(actual)==7 and
                reference==old==actual,
                "Native candidate/baseline/independent-reference difference "+label)
        arm,mode=route(trace)
        expected_arm="lower" if label in LOWER_LABELS else "upper"
        require(arm==expected_arm,
                "Native w changed upstream input-selected logic branch "+label)
        counts[arm]+=1
        if mode is not None:
            modes.add(mode)
            if mode=="right" and right_case is None:
                right_case=(label,raw,reference)
        with open(trace,"rb") as stream:
            digest=hashlib.sha256(stream.read()).hexdigest()
        reports.append({"case":label,"valid":valid,"arm":arm,"w_mode":mode,
                        "trace_file":label+".tsv",
                        "trace_sha256":digest,"seven_field_native_parity":True})
        print("NATIVE_W_DATA_COMPARATOR_AND_ORACLE_PASS",
              label,arm,mode,"seven_fields")
        sys.stdout.flush()
    require(counts=={"upper":11,"lower":6} and
            modes==set(("straight","right")) and right_case is not None,
            "actual Native data did not exercise both w comparator outcomes")
    # Wider valid and malformed signed-domain differential uses three independent
    # Native Befunge reference programs and the unchanged promoted baseline.
    extended=[]
    for label,fields,valid in wide.CASES:
        raw=" ".join(map(str,fields))+"\n"
        expect=suite.expected_for(*fields) if valid else ["-1"]*7
        prior=suite.native(BASE,raw)
        candidate=suite.native(SOURCE_FILE,raw)
        require(len(expect)==len(prior)==len(candidate)==7 and
                candidate==prior==expect,
                "w candidate wider Native Befunge oracle mismatch "+label)
        extended.append({"case":label,"valid":valid,
                         "native_reference_equal":True})
        print("NATIVE_W_EXTENDED_SIGNED_DOMAIN_PASS",label)
        sys.stdout.flush()
    require(len(extended)==22 and sum(bool(x["valid"]) for x in extended)==18,
            "wide valid/invalid domains unexpectedly changed")
    mutant(data,edits)
    label,raw,expected=right_case
    rc,altered,stderr=call_bounded(MUTANT_FILE,raw,8)
    require(rc==0 and altered!=expected,
            "executed w is mathematically inert or the counterfactual did not halt: "+
            repr((label,rc,altered,expected,stderr)))
    print("NATIVE_W_SEMANTIC_SINGLE_BYTE_CAUSAL_CONTROL_PASS",
          label,"mutant_exit",rc,"output_changed",True)
    report={"schema":"befunge-stage1-native-w-data-selected-arithmetic-v1",
            "status":"QA_CANDIDATE_ONLY_NOT_PROMOTED",
            "exact_source_sha256":hashlib.sha256(data).hexdigest(),
            "changed_source_cells":len(edits),"valid_native_cases":14,
            "invalid_native_cases":3,"branch_counts":counts,
            "real_native_comparison_modes":sorted(modes),
            "single_executed_w_removal_changes_output":True,
            "cases":reports,
            "extended_signed_domain_cases":extended,
            "frozen_candidate_git_blob":FROZEN_BLOB}
    with open(os.path.join(OUT,"w_data_candidate_proof.json"),"wb") as sink:
        sink.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_W_DATA_DEPENDENT_ARITHMETIC_QA_PASS",len(reports),
          "Native cases, w changes arithmetic output if removed")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; no src promotion or Stage 2")

if __name__=="__main__":
    main()
