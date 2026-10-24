#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Strict read-only Native discovery of valid-input w comparator path diversity.

All date arithmetic/oracles remain in Native Befunge-98. Python only
enumerates signed input vectors, calls pinned PyFunge, checks seven output
tokens from independent Befunge references, and reads actual interpreter
STEP traces. A missing valid outcome is recorded as a coverage gap, NOT
silently declared PASS or interpreted as a numerical bug.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_diverse_geometry as suite
import stage1_native_reflective_candidate_domain_matrix as wide

SOURCE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
OUT="/wvalid"
EXPECTED_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
W=(951,1332)
MODES={(952,1332):"right",(951,1331):"straight"}
H=2**127
E=10**40+987654321
MORE=[
  ("valid_same_small_zero",(0,0,0,0)),
  ("valid_same_small_positive",(0,3,0,3)),
  ("valid_same_negative",(1,3,1,3)),
  ("valid_equal_anchor",(0,15055671,0,15055671)),
  ("valid_just_beyond_anchor",(0,15055672,0,15055673)),
  ("valid_cross_near_anchor",(1,15055672,0,15055671)),
  ("valid_cross_back_anchor",(0,15055671,1,15055672)),
  ("valid_one_left",(1,1,0,0)),
  ("valid_one_right",(0,0,1,1)),
  ("valid_two_negative",(1,2,1,1)),
  ("valid_huge_same",(0,H,0,H)),
  ("valid_huge_adjacent",(0,H+1,0,H)),
  ("valid_huge_negative_adjacent",(1,H+1,1,H)),
  ("valid_huge_cross",(1,H,0,H)),
  ("valid_huge_cross_reverse",(0,H,1,H)),
  ("valid_huge_to_one",(0,H,0,1)),
  ("valid_one_to_huge",(0,1,0,H)),
  ("valid_huge_negative_to_one",(1,H,1,1)),
  ("valid_one_to_huge_negative",(1,1,1,H)),
  ("valid_decimal_equal",(0,E,0,E)),
  ("valid_decimal_adjacent",(0,E,0,E+1)),
  ("valid_decimal_back",(0,E+1,0,E)),
  ("valid_decimal_cross",(1,E,0,E)),
  ("valid_decimal_cross_reverse",(0,E,1,E)),
  ("valid_far_positive_to_zero",(0,10**77,0,0)),
  ("valid_zero_to_far_positive",(0,0,0,10**77)),
  ("valid_far_negative_to_positive",(1,10**77,0,10**78)),
  ("valid_far_positive_to_negative",(0,10**78,1,10**77)),
]
def require(ok,msg):
    if not ok:raise AssertionError(msg)

def git_blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def native_mode(trace):
    pending=False
    count=0
    dest=None
    with open(trace,"rb") as stream:
        for line in stream:
            if not line.startswith("STEP\t"):continue
            parts=line.rstrip("\n").split("\t")
            require(len(parts)==9,"malformed Native interpreter STEP event")
            tick,ip,x,y,dx,dy,op,depth=map(int,parts[1:])
            if pending:
                require(dest is None,"Native w STEP repeated before control join")
                dest=(x,y)
                pending=False
            if (x,y)==W:
                count+=1
                require(op==ord("w") and depth==3,
                        "Native w comparator entered with unexpected instruction/stack")
                pending=True
    require(count<=1 and not pending,"w Native IP loop / missing successor")
    if count==0:
        return "skipped"
    require(dest in MODES,"w routed outside approved Native comparator lanes")
    return MODES[dest]

def main():
    require(os.path.isdir(OUT),"native wide-branch artifact directory missing")
    code=open(SOURCE,"rb").read()
    require(git_blob(code)==EXPECTED_BLOB,
            "exact QA w experimental source SHA drift")
    cases=[]
    for label,fields,valid in wide.CASES:
        cases.append(("wide_"+label,fields,valid))
    for label,fields in MORE:
        cases.append((label,fields,True))
    require(len(cases)==len(wide.CASES)+len(MORE) and
            len({z[0] for z in cases})==len(cases),
            "Native input search corpus changed or repeated labels")
    tested=[]
    groups={"valid":{"right":0,"straight":0,"skipped":0},
            "invalid":{"right":0,"straight":0,"skipped":0}}
    for name,fields,valid in cases:
        input_text=" ".join(map(str,fields))+"\n"
        oracle=suite.expected_for(*fields) if valid else ["-1"]*7
        old=suite.native("qa/interleaved_work_counts_pre_two_valid_w_production.b98",input_text)
        path=os.path.join(OUT,name+".tsv")
        got=suite.native(SOURCE,input_text,trace=path)
        require(len(oracle)==len(old)==len(got)==7 and
                oracle==old==got,"Native signed input numerical parity lost "+name)
        mode=native_mode(path)
        groups["valid" if valid else "invalid"][mode]+=1
        with open(path,"rb") as stream:
            digest=hashlib.sha256(stream.read()).hexdigest()
        tested.append({"case":name,"fields":list(fields),"valid":valid,
                       "branch":mode,"native_trace_sha256":digest,
                       "trace_file":name+".tsv"})
        print("NATIVE_W_SIGNED_DOMAIN_BRANCH_DISCOVERY",name,
              "valid",valid,"w",mode)
        sys.stdout.flush()
    require(sum(groups["valid"].values())==len([z for z in cases if z[2]])
            and sum(groups["invalid"].values())==len([z for z in cases if not z[2]]),
            "Native computed comparison counts do not sum to corpus")
    gap=not (groups["valid"]["right"] and groups["valid"]["straight"])
    report={"schema":"befunge-stage1-w-valid-branch-native-discovery-v1",
            "source_blob":EXPECTED_BLOB,
            "status":"QA_DISCOVERY_NOT_STAGE1_ACCEPTANCE",
            "case_count":len(tested),"branch_counts":groups,
            "two_valid_comparison_outcomes_proved":not gap,
            "valid_branch_diversity_gap_open":gap,
            "cases":tested}
    with open(os.path.join(OUT,"w_valid_branch_discovery.json"),"wb") as fp:
        fp.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_W_VALID_DOMAIN_DISCOVERY_COMPLETE",len(tested),
          "valid",groups["valid"],"invalid",groups["invalid"],
          "TWO_VALID_OUTCOMES_PROVED",not gap)
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; evidence discovery, not acceptance")

if __name__=="__main__":
    main()
