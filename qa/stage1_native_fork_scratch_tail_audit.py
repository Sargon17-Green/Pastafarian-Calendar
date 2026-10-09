#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent adversarial consistency audit of Native scratch-tail replay."""
import copy
import json
import os
import sys
from pathlib import Path

SCRATCH=(1490,1600)
SOURCE_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"

def check(ok,message):
    if not ok:
        raise AssertionError(message)

def sig(run):
    return (run["status"],run["remaining_ips"],run["output"])

def verify(report,prior):
    check(report.get("schema")=="befunge-stage1-native-scratch-tail-v1" and
          report.get("source_git_blob")==SOURCE_BLOB and
          report.get("status")=="QA_ONLY_SCRATCH_LIVENESS_BOUNDED" and
          report.get("scratch_coordinate")==list(SCRATCH) and
          report.get("full_execution_state_equivalence_proven") is False and
          report.get("native_real_program_executions")==128 and
          report.get("single_cell_mutant_executions")==64 and
          report.get("branch_pairs")==64 and
          report.get("valid_input_cases")==32,
          "Native trial counts/source/status inconsistent")
    rows=report.get("records")
    originals=prior.get("records")
    check(isinstance(rows,list) and len(rows)==32 and
          isinstance(originals,list) and len(originals)==32 and
          [row["case"] for row in rows]==[x["case"] for x in originals],
          "scratch evidence missing/misordered/duplicate")
    changed=0
    for row,old in zip(rows,originals):
        klass=old["gate_observed_nonzero"]
        check(row["gate_observed_nonzero"]==klass and
              isinstance(row["branches"],list) and
              len(row["branches"])==2,
              "scratch input/branch class mismatch")
        for index,entry in enumerate(row["branches"]):
            forced=index==1
            executed=1-klass if forced else klass
            refmotion=old["first_common_five_event_motion"]
            expected_offset=refmotion[
                "mutant_offset" if forced else "original_offset"]
            baseline=entry["native_control"]
            mutant=entry["native_scratch_flipped"]
            event0=baseline["event"]
            event1=mutant["event"]
            expected_value=12 if executed else 32
            changed_real=sig(baseline)!=sig(mutant)
            check(entry["branch"]==
                  ("forced-opposite" if forced else "natural") and
                  entry["expected_executed_gate_nonzero"]==executed and
                  entry["rejoin_offset"]==expected_offset and
                  baseline["steps"]==old[
                      "mutant_step_count" if forced else "control_step_count"] and
                  baseline["status"]==old[
                      "mutant_status" if forced else "control_status"] and
                  event0["motion"]==refmotion["real_motion_sample"][0] and
                  event1["motion"]==event0["motion"] and
                  event0["scratch_before"]==expected_value and
                  event0["scratch_after"]==expected_value and
                  event0["intervention_performed"] is False and
                  event1["intervention_performed"] is True and
                  event1["scratch_before"]==expected_value and
                  event1["scratch_after"]==(32 if expected_value==12 else 12) and
                  event1["tick"]==event0["tick"] and
                  entry["post_rejoin_semantics_changed"]==changed_real and
                  entry["post_rejoin_step_count_changed"]==(
                      baseline["steps"]!=mutant["steps"]),
                  "native bounded scratch intervention/source replay contradiction")
            for trial in (baseline,mutant):
                check(trial["status"] in ("normal","step-limit") and
                      type(trial["remaining_ips"]) is int and
                      type(trial["steps"]) is int and
                      trial["steps"]>=1 and
                      isinstance(trial["output"],list) and
                      all(isinstance(x,str) for x in trial["output"]) and
                      all(type(n) is int and n>=0
                          for n in trial["post_checkpoint"].values()),
                      "Native tail-execution or memory-read counters malformed")
            changed+=int(changed_real)
    check(report["observed_semantic_change_pairs"]==changed,
          "scrub effect aggregate forged")
    return changed

def main(folder):
    folder=Path(folder)
    with (folder/"native_fork_scratch_tail_counterfactual.json").open(
            encoding="utf-8") as f:
        data=json.load(f)
    with (folder/"current_fork_native_route_differential.json").open(
            encoding="utf-8") as f:
        prior=json.load(f)
    total=verify(data,prior)
    print("NATIVE_FORK_SCRATCH_TAIL_INDEPENDENT_64_PAIR_PASS",
          "changed_pairs",total)
    def must_fail(name,mutate):
        forged=copy.deepcopy(data)
        mutate(forged)
        try:
            verify(forged,prior)
        except AssertionError:
            print("NATIVE_FORK_SCRATCH_TAIL_TAMPER_REJECT_PASS",name)
            return name
        raise AssertionError("tampered Native scrub evidence passed: "+name)
    rejected=[
        must_fail("wrong_source",lambda p:p.__setitem__("source_git_blob","0"*40)),
        must_fail("wrong_scratch",lambda p:p.__setitem__("scratch_coordinate",[0,0])),
        must_fail("dropped_case",lambda p:p["records"].pop()),
        must_fail("forged_prevalue",lambda p:p["records"][0]["branches"][0]
                  ["native_scratch_flipped"]["event"].__setitem__(
                      "scratch_before",999)),
        must_fail("omitted_intervention",lambda p:p["records"][0]["branches"][0]
                  ["native_scratch_flipped"]["event"].__setitem__(
                      "intervention_performed",False)),
        must_fail("false_output_class",lambda p:p["records"][0]["branches"][0]
                  .__setitem__("post_rejoin_semantics_changed",
                               not p["records"][0]["branches"][0]
                               ["post_rejoin_semantics_changed"])),
        must_fail("incorrect_total",lambda p:p.__setitem__(
            "observed_semantic_change_pairs",65))
    ]
    check(len(rejected)==7,"adversarial tail audit incomplete")
    out={"schema":"befunge-stage1-native-scratch-tail-audit-v1",
         "source_git_blob":SOURCE_BLOB,
         "valid_records":32,"branch_pairs":64,
         "adversarial_mutations_rejected":rejected,
         "observed_semantic_change_pairs":total,
         "stage1_final_approval":False}
    with (folder/"native_fork_scratch_tail_audit.json").open(
            "w",encoding="utf-8") as f:
        json.dump(out,f,indent=2,sort_keys=True)
        f.write("\n")
    print("NATIVE_FORK_SCRATCH_TAIL_7_ADVERSARIAL_AUDIT_PASS")

if __name__=="__main__":
    check(len(sys.argv)==2,"usage: SCRATCH_EVIDENCE_FOLDER")
    main(sys.argv[1])
