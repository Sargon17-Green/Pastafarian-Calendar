#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Stage-1 12 valid + 1 invalid four-cell loop-dependency controls.

Rebuild a TEST-ONLY 2D Befunge-98 source from four fixed Funge-space cell
changes, pinned to its observed Native Git blob. Each of twelve previously
source-measured lower-| cases gets a genuine PyFunge control and a one-op
']' to '[' counterfactual. The invalid case is an error-preservation control.
All seven numeric reference outputs come from independent real Befunge-98
modules, never from Python calendar implementations. Candidate stays QA-only.
"""
from __future__ import print_function
import json
import os
import sys
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide
import stage1_native_lower_feedback_rejoin as lower
import stage1_native_lower_feedback_semantic_candidate as builder
import stage1_native_lower_feedback_twelve_valid as prior

OUT="/candidate-wide"
SOURCE="src/interleaved_work_counts.b98"
PRODUCTION_PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE_PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
VALID_CASES=prior.LABELS
ERROR_CASE="invalid_zero_sign"

def require(ok,reason):
    if not ok:raise AssertionError(reason)

def main():
    require(os.path.isdir(OUT),"missing Native candidate-wide evidence directory")
    original=open(SOURCE,"rb").read()
    require(builder.git_blob(original)==PRODUCTION_PIN,
            "Native production source identity changed")
    mutant_source=builder.candidate_bytes(original)
    require(builder.git_blob(mutant_source)==CANDIDATE_PIN,
            "four-cell candidate bytes differ from 39-of-39 oracle-green variant")
    with open(OUT+"/four_cell_candidate.b98","wb") as f:
        f.write(mutant_source)
    book=dict((a,(b,c)) for a,b,c in list(native.CASES)+list(wide.CASES))
    labels=tuple(VALID_CASES)+(ERROR_CASE,)
    require(len(labels)==13 and len(set(labels))==13,
            "wide Native lower causal input labels are not unique")
    records=[]
    for label in labels:
        fields,valid=book[label]
        require(bool(valid)==(label!=ERROR_CASE),
                "invalid Native test input cannot be used as valid reference")
        raw=" ".join(map(str,fields))+"\n"
        expected=native.expected_for(*fields) if valid else ["-1"]*7
        require(len(expected)==7,"Native independent oracle incomplete")
        control=lower.run(mutant_source,raw,False)
        flipped=lower.run(mutant_source,raw,True)
        require(control["status"]=="normal" and
                control["remaining_ips"]==0 and control["output"]==expected,
                "unchanged 4-cell candidate diverged from Native seven-field oracle: "+label)
        require(flipped["status"]=="normal" and flipped["remaining_ips"]==0,
                "opposite first Native lower turn did not finish normally: "+label)
        require(control["gate"]["executed_opcode"]=="]" and
                flipped["gate"]["executed_opcode"]=="[" and
                control["gate"]["tick"]==flipped["gate"]["tick"] and
                control["gate"]["direction_before"]==
                    flipped["gate"]["direction_before"] and
                control["gate"]["direction_after"]!=
                    flipped["gate"]["direction_after"] and
                control["gate"]["restored"] and flipped["gate"]["restored"],
                "a single real lower-turn instruction was not inverted and restored: "+label)
        control_literal=sum(x["motion"][:2]==[951,1337] and
                            x["opcode"]==ord("1") for x in control["post"])
        flipped_literal=sum(x["motion"][:2]==[951,1337] and
                            x["opcode"]==ord("1") for x in flipped["post"])
        effect=(control["status"]!=flipped["status"] or
                control["remaining_ips"]!=flipped["remaining_ips"] or
                control["output"]!=flipped["output"])
        require(effect is bool(valid),
                "lower-loop valid-input causal dependency or invalid no-op failed: "+label)
        require(control_literal>=1 and flipped_literal==0,
                "new arithmetic literal was not executed only in required lower loop: "+label)
        common=lower.common_motion(control["post"],flipped["post"],5)
        observations=[]
        if common is not None:
            for i in range(5):
                a=control["post"][common[0]+i]
                b=flipped["post"][common[1]+i]
                require(a["motion"]==b["motion"] and a["opcode"]==b["opcode"],
                        "reported common Native motion/opcode was not identical")
                observations.append({
                    "native_motion":a["motion"],
                    "native_opcode":a["opcode"],
                    "control_frames":a["frames"],"flipped_frames":b["frames"],
                    "control_ip_context":a["ip_context"],
                    "flipped_ip_context":b["ip_context"],
                    "control_p_modified":a["p_modified_cells"],
                    "flipped_p_modified":b["p_modified_cells"],
                    "equal_frames":a["frames"]==b["frames"],
                    "equal_context":a["ip_context"]==b["ip_context"],
                    "equal_p_modified":a["p_modified_cells"]==b["p_modified_cells"]
                })
        records.append({
            "case":label,"valid":bool(valid),"input_fields":list(fields),
            "reference_output":expected,
            "original":{k:v for k,v in control.items() if k!="post"},
            "opposite_turn":{k:v for k,v in flipped.items() if k!="post"},
            "real_literal_executed_control":control_literal,
            "real_literal_executed_opposite":flipped_literal,
            "first_shared_native_motion_indices":list(common) if common else None,
            "five_shared_native_motion_comparisons":observations,
            "changed_output_or_termination":bool(effect),
            "changed_all_seven_fields":all(a!=b for a,b in zip(
                control["output"],flipped["output"])),
        })
        print("NATIVE_FOUR_CELL_LOWER_12_VALID_DEPENDENCY_PASS",label,
              "valid",bool(valid),"literal",control_literal,"to",
              flipped_literal,"changed_final",effect,
              "common_five",common,"original_steps",control["steps"],
              "flipped_steps",flipped["steps"])
        sys.stdout.flush()
    require(len(records)==13 and sum(x["valid"] for x in records)==12,
            "complete twelve valid plus one invalid Native experiment missing")
    valid_rows=[r for r in records if r["valid"]]
    invalid_rows=[r for r in records if not r["valid"]]
    require(all(r["changed_output_or_termination"] for r in valid_rows)
            and all(not r["changed_output_or_termination"] for r in invalid_rows),
            "Native lower-loop semantic causality classification changed")
    result={
       "schema":"befunge-stage1-native-four-cell-12-valid-causality-v1",
       "status":"EXPLORATORY_NOT_PRODUCTION_STAGE1_OPEN",
       "original_production_git_blob":PRODUCTION_PIN,
       "candidate_git_blob":CANDIDATE_PIN,
       "four_cells_modified":[list(p) for p in builder.PATCHES],
       "real_native_programs":26,
       "real_native_intervention_pairs":13,
       "valid_cases":12,"invalid_cases":1,
       "native_valid_oracle_cases":12,
       "native_valid_causal_cases":sum(x["changed_output_or_termination"] for x in valid_rows),
       "native_invalid_preserved":sum(not x["changed_output_or_termination"]
                                      for x in invalid_rows),
       "valid_literal_control_visits":sum(x["real_literal_executed_control"]
                                          for x in valid_rows),
       "valid_literal_mutant_visits":sum(x["real_literal_executed_opposite"]
                                         for x in valid_rows),
       "stage1_complete":False,
       "qa_production_modified":False,"canonical_branch_modified":False,
       "records":records
    }
    with open(OUT+"/four_cell_twelve_valid_causality.json","wb") as f:
        f.write(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("NATIVE_QA_FOUR_CELL_TWELVE_VALID_ACTUAL_CAUSAL_PASS",
          result["native_valid_causal_cases"],"of",len(valid_rows),
          "invalid_preserved",result["native_invalid_preserved"])
    print("QA_ONLY LAST_COMPLETED_STAGE=0 GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":main()
