#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage1: Native twelve *valid* lower-branch feedback reconvergence audit.

Test exact known gate=0 valid families selected from the separately archived
32-case PyFunge real-| corpus (artifact 11666777943). Run 24 new genuine
PyFunge programs, one unmodified and one one-instruction ] -> [ per case.
The source instruction is restored immediately after execution. Numerical
reference comes ONLY from independent Befunge-98 modules, not Python.
Classify 18-instruction bypass, five real common-step motion and measured
complete TOSS/SOSS, mutable p-cell, IP mode/offset/input cursor and stdout
prefix. Do not infer whole state equivalence or Stage-1 completion.
"""
from __future__ import print_function
import json
import os
import sys
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide
import stage1_native_lower_feedback_rejoin as prior

OUT="/lower-wide/native_lower_wide_rejoin.json"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
LABELS=(
 "foundation_cross","mixed_small","negative_positive",
 "foundation_neighbor_forward","foundation_neighbor_reverse",
 "negative_equal_high","negative_high_forward","negative_high_reverse",
 "cross_high_forward","foundation_to_origin","foundation_to_recent",
 "decimal_cross_reverse",
)

def require(ok,why):
    if not ok:raise AssertionError(why)

def main():
    require(os.path.isdir("/lower-wide"),"missing lower-wide native evidence destination")
    source=open(prior.SOURCE,"rb").read()
    require(prior.sha(source)==PIN,"QA Native production source identity changed")
    casebook=dict((row[0],(row[1],row[2])) for row in native.CASES)
    casebook.update((row[0],(row[1],row[2])) for row in wide.CASES)
    require(len(LABELS)==12 and len(set(LABELS))==12,
            "native 12-case real lower-gate corpus altered")
    records=[]
    for label in LABELS:
        require(label in casebook,"missing pinned lower-gate input "+label)
        fields,valid=casebook[label]
        require(valid,"this native lower-probe requires valid oracle cases")
        raw=" ".join(map(str,fields))+"\n"
        oracle=native.expected_for(*fields)
        require(len(oracle)==7,"independent native Befunge oracle malformed")
        base=prior.run(source,raw,False)
        mutant=prior.run(source,raw,True)
        require(base["status"]==mutant["status"]=="normal"
                and base["remaining_ips"]==mutant["remaining_ips"]==0
                and base["output"]==mutant["output"]==oracle,
                "Native lower feedback bypass changed seven-value output "+label)
        require(base["steps"]-mutant["steps"]==18,
                "Native lower feedback bypass differs from exactly eighteen instructions")
        a,b=base["gate"],mutant["gate"]
        require(a["executed_opcode"]=="]" and b["executed_opcode"]=="["
                and a["restored"] and b["restored"]
                and a["tick"]==b["tick"]
                and a["direction_before"]==b["direction_before"]
                and a["direction_after"]!=b["direction_after"],
                "genuine single Native executable turn intervention missing "+label)
        match=prior.common_motion(base["post"],mutant["post"],5)
        require(match is not None and match==(18,0),
                "Native lower feedback first common 5-motion window not exactly 18-to-0 "+label)
        # In the actually skipped Native 18-step execution there is neither
        # a Funge-space p/g nor s (put-next) memory access, nor IO or thread
        # creation. This does not guarantee no OTHER engine-level APIs,
        # but prevents a dynamic path from being counted as dataflow via p/g.
        skipped=base["post"][:18]
        require(len(skipped)==18 and
                not any(item["opcode"] in
                        tuple(ord(c) for c in "pgs~&,.=iot")
                        for item in skipped),
                "lower feedback bypass newly performs memory/IO/concurrency")
        compared=[]
        for i in range(5):
            first=base["post"][18+i]
            second=mutant["post"][i]
            require(first["motion"]==second["motion"] and
                    first["opcode"]==second["opcode"],
                    "native 5-step shared directed IP motion/opcode was forged")
            flags={
              "frames": first["frames"]==second["frames"],
              "context": first["ip_context"]==second["ip_context"],
              "p_modified":first["p_modified_cells"]==second["p_modified_cells"],
              "stdout":first["stdout_prefix"]==second["stdout_prefix"],
            }
            compared.append({
              "step":i,
              "native_motion":first["motion"],
              "native_opcode":first["opcode"],
              "control_frames":first["frames"],
              "mutant_frames":second["frames"],
              "control_context":first["ip_context"],
              "mutant_context":second["ip_context"],
              "control_p_modified":first["p_modified_cells"],
              "mutant_p_modified":second["p_modified_cells"],
              "control_stdout_prefix":first["stdout_prefix"],
              "mutant_stdout_prefix":second["stdout_prefix"],
              "equal":flags})
        totals=dict((name,sum(z["equal"][name] for z in compared))
                    for name in ("frames","context","p_modified","stdout"))
        records.append({
           "case":label,"input_fields":list(fields),"reference_output":oracle,
           "control_status":base["status"],"mutant_status":mutant["status"],
           "control_output":base["output"],"mutant_output":mutant["output"],
           "control_steps":base["steps"],"mutant_steps":mutant["steps"],
           "native_gate_tick":a["tick"],
           "native_gate_direction_before":a["direction_before"],
           "control_gate_direction_after":a["direction_after"],
           "mutant_gate_direction_after":b["direction_after"],
           "native_source_instruction_restored":True,
           "first_common_motion_indices":[18,0],
           "skipped_native_opcodes":[z["opcode"] for z in skipped],
           "five_common_state_records":compared,
           "five_common_state_equals":totals,
           "post_gate_control_p_count":base["post_p_instructions"],
           "post_gate_mutant_p_count":mutant["post_p_instructions"],
           "post_gate_control_g_count":base["post_g_instructions"],
           "post_gate_mutant_g_count":mutant["post_g_instructions"],
        })
        print("NATIVE_LOWER_12_VALID_REAL_REJOIN_MEASURED",label,
              "five_equal",totals,"steps_saved",18)
        sys.stdout.flush()
    summary=dict((name,sum(row["five_common_state_equals"][name]==5
                        for row in records))
                  for name in ("frames","context","p_modified","stdout"))
    report={
        "schema":"befunge-stage1-lower-feedback-twelve-wide-rejoin-v1",
        "production_git_blob":PIN,
        "status":"OBSERVED_NATIVE_TWELVE_CASE_BYPASS_NOT_ACCEPTANCE",
        "source_corpus_artifact_id":11666777943,
        "native_case_count":12,"native_program_executions":24,
        "native_oracle_cases":12,
        "bypass_instruction_count":18,
        "scc_lower_cell":[951,1336],
        "summary_all_five_equal_cases":summary,
        "stage1_geometry_gate":"OPEN",
        "last_completed_stage":0,
        "records":records,
    }
    with open(OUT,"wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_LOWER_12_VALID_FEEDBACK_REJOIN_PROFILE_PASS",
          json.dumps(summary,sort_keys=True))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO STAGE1_OPEN")

if __name__=="__main__":
    main()
