#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Pure Befunge Stage1: exploratory four-cell lower feedback candidate.

Patch a TEST-ONLY in-memory copy of the pinned 2D Befunge program. Move the
mandatory literal '1' from immediately AFTER the lower loop to just BEFORE
that loop rejoins, by redirecting a dynamically computed x jump one row
lower, then turning north and executing '1' inside the feedback circuit.

Candidate source remains an emitted CI artifact; never edits qa src, the
canonical branch, or main. All calendar numeric outputs are computed by
genuine Native Befunge-98 and independent Befunge reference programs, not
Python. Contrast six known lower-route inputs with a genuinely executed,
temporarily inverted turn operator to measure whether the loop now has a
causal role; do not assume or auto-promote candidate on any outcome.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide
import stage1_native_lower_feedback_rejoin as lower

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT="/lower-candidate"
CANDIDATE=OUT+"/lower_feedback_semantic_candidate.b98"
# Every changed cell exists, is executed by the measured lower route except
# its one new turn cell, and the old rejoin numeral moves INSIDE the loop.
PATCHES=(
    (948,1331,"6","7"),   # native dynamic x: (8,6) -> (8,7)
    (951,1337,"^","1"),   # native lower-loop arithmetic literal before rejoin
    (951,1338," ","^"),   # new vertical route from altered x landing
    (952,1336,"1"," "),   # no duplicate after rejoin; upper route on y1334 intact
)
LOWER_SIX=(
  "foundation_cross","mixed_small","negative_positive",
  "invalid_zero_sign","foundation_neighbor_forward",
  "foundation_neighbor_reverse",
)
def require(ok,why):
    if not ok:raise AssertionError(why)
def git_blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def candidate_bytes(source):
    rows=source.split("\n")
    require(len(rows)==2016 and max(map(len,rows))==1531,
            "frozen native source dimensions changed")
    for x,y,before,after in PATCHES:
        require(rows[y][x]==before,
                "candidate source-map preimage differs at (%d,%d)"%(x,y))
        rows[y]=rows[y][:x]+after+rows[y][x+1:]
    result="\n".join(rows)
    require(len(result)==len(source),"QA candidate changed source dimensions")
    for y,(old,new) in enumerate(zip(source.split("\n"),result.split("\n"))):
        different=[x for x,(a,b) in enumerate(zip(old,new)) if a!=b]
        require(different==sorted(x for x,yy,_,_ in PATCHES if yy==y),
                "unexpected non-local source map edit at row %d"%y)
    return result

def main():
    require(os.path.isdir(OUT),"native QA candidate evidence volume absent")
    source=open(SOURCE,"rb").read()
    require(git_blob(source)==PIN,"active Befunge source Git blob changed")
    patched=candidate_bytes(source)
    with open(CANDIDATE,"wb") as dest:dest.write(patched)
    sha=git_blob(patched)
    print("NATIVE_QA_ONLY_CANDIDATE_FOUR_CELL_SOURCE_MAP_PASS",
          "old",PIN,"new",sha)
    sys.stdout.flush()
    cases=list(native.CASES)+list(wide.CASES)
    require(len(cases)==39 and len(set(row[0] for row in cases))==39,
            "native differential test corpus malformed")
    oracle_rows=[]
    for label,fields,valid in cases:
        raw=" ".join(map(str,fields))+"\n"
        expected=native.expected_for(*fields) if valid else ["-1"]*7
        result={"case":label,"valid":bool(valid),"input_fields":list(fields),
                "reference_output":expected}
        try:
            observed=native.native(CANDIDATE,raw)
            result["candidate_output"]=observed
            result["native_cli_complete"]=True
            result["seven_field_parity"]=(observed==expected)
        except Exception as e:
            result["native_cli_complete"]=False
            result["seven_field_parity"]=False
            result["native_failure"]=str(e)[:300]
        oracle_rows.append(result)
        print("NATIVE_QA_ONLY_CANDIDATE_REFERENCE_MEASURED",label,
              "completed",result["native_cli_complete"],
              "parity",result["seven_field_parity"])
        sys.stdout.flush()
    references_all_green=all(item["seven_field_parity"] for item in oracle_rows)
    book=dict((label,(fields,valid)) for label,fields,valid in cases)
    trial_rows=[]
    if references_all_green:
        for label in LOWER_SIX:
            fields,valid=book[label]
            raw=" ".join(map(str,fields))+"\n"
            unmodified=lower.run(patched,raw,False)
            changed=lower.run(patched,raw,True)
            expected=native.expected_for(*fields) if valid else ["-1"]*7
            require(unmodified["status"]=="normal"
                    and unmodified["remaining_ips"]==0
                    and unmodified["output"]==expected
                    and unmodified["gate"]["executed_opcode"]=="]"
                    and changed["gate"]["executed_opcode"]=="["
                    and unmodified["gate"]["restored"]
                    and changed["gate"]["restored"]
                    and changed["gate"]["tick"]==unmodified["gate"]["tick"]
                    and changed["gate"]["direction_after"]!=
                        unmodified["gate"]["direction_after"],
                    "real Native candidate turn counterfactual was not applied "+label)
            effect=(changed["status"]!="normal" or
                    changed["remaining_ips"]!=0 or changed["output"]!=expected)
            trial_rows.append({
                "case":label,"valid":valid,
                "original":{k:v for k,v in unmodified.items() if k!="post"},
                "inverted_turn":{k:v for k,v in changed.items() if k!="post"},
                "native_full_result_or_termination_effect":effect})
            print("NATIVE_QA_ONLY_CANDIDATE_LOWER_LOOP_CAUSALITY_MEASURED",
                  label,"observable_effect",effect,
                  "mutant_status",changed["status"])
            sys.stdout.flush()
    else:
        print("NATIVE_QA_CANDIDATE_REJECTED_NUMERICAL_PARITY",
              "candidate not run through downstream causal promotion")
    report={
       "schema":"befunge-stage1-native-qa-lower-feedback-four-cell-candidate-v1",
       "status":"EXPLORATORY_QA_CANDIDATE_NOT_PROMOTED",
       "production_git_blob":PIN,"candidate_git_blob":sha,
       "exact_source_cell_changes":[list(p) for p in PATCHES],
       "native_oracle_case_count":len(oracle_rows),
       "native_oracle_parity_cases":sum(x["seven_field_parity"] for x in oracle_rows),
       "independent_befunge_reference_parity_full":references_all_green,
       "native_lower_causal_trial_pairs":len(trial_rows),
       "native_lower_causal_effect_cases":sum(
           x["native_full_result_or_termination_effect"] for x in trial_rows),
       "candidate_ready_for_promotion":(references_all_green
          and len(trial_rows)==6 and all(
             x["native_full_result_or_termination_effect"] for x in trial_rows)),
       "stage1_functional_acceptance":False,
       "stage1_geometric_acceptance":False,
       "qa_production_modified":False,"canonical_branch_modified":False,
       "oracle_rows":oracle_rows,"counterfactuals":trial_rows}
    with open(OUT+"/lower_feedback_candidate_experiment.json","wb") as target:
        target.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_LOWER_FEEDBACK_FOUR_CELL_CANDIDATE_MEASURED_PASS",
          "numeric",report["native_oracle_parity_cases"],"of",len(oracle_rows),
          "causal",report["native_lower_causal_effect_cases"],
          "of",len(trial_rows),"candidate_ready",report["candidate_ready_for_promotion"])
    print("QA_ONLY; GEOMETRIC_SPAGHETTI_QA_PASS=NO, STAGE2_STARTED=NO")

if __name__=="__main__":
    main()
