#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent SHA-pinned QA audit for 20 real Native pre-g read interventions."""
import copy
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def need(ok,why):
    if not ok:raise AssertionError(why)
def sig(x):
    return x["status"],x["remaining_ips"],x["output"]
def verify(data,previous):
    need(data.get("schema")=="befunge-stage1-pre-g-native-scratch-v1" and
         data.get("status")=="QA_ONLY_EARLY_READ_CAUSALITY" and
         data.get("source_git_blob")==PIN and
         data.get("scratch_coordinate")==[1490,1600] and
         data.get("valid_inputs")==20 and
         data.get("real_native_executions")==40 and
         data.get("g_return_value_changed_pairs")==20 and
         data.get("stage1_final_acceptance") is False,
         "pre-g Native manifest/source/policy disagreement")
    originals={row["case"]:row for row in previous["records"]
               if row["gate_observed_nonzero"]==1}
    rows=data.get("records")
    need(isinstance(rows,list) and len(rows)==20 and
         set(row["case"] for row in rows)==set(originals) and
         len(set(row["case"] for row in rows))==20,
         "Native pre-g corpus missing/duplicate or wrong fork class")
    changed=0
    for row in rows:
        orig=originals[row["case"]]
        a=row["control"]
        b=row["mutant"]
        x=a["real_g"]
        y=b["real_g"]
        need(a["status"]=="normal" and a["remaining_ips"]==0 and
             a["steps"]==orig["control_step_count"] and
             x["coordinate"]==y["coordinate"]==[1490,1600] and
             x["step"]==y["step"] and
             x["before_read"]==x["g_returned"]==12 and
             y["before_read"]==y["g_returned"]==32 and
             x["intervened"] is False and
             y["intervened"] is True and
             row["final_semantics_changed"]==(sig(a)!=sig(b)) and
             row["step_count_changed"]==(a["steps"]!=b["steps"]) and
             isinstance(a["output"],list) and
             isinstance(b["output"],list) and
             b["status"] in ("normal","step-limit"),
             "Native pre-g g-value/time/output check contradicted")
        changed+=int(row["final_semantics_changed"])
    need(data.get("final_semantic_changed_pairs")==changed,
         "pre-g final semantics tally contradicts individual results")
    return changed
def main(folder):
    folder=Path(folder)
    with (folder/"native_pre_g_scratch_intervention.json").open(
            encoding="utf-8") as f:
        data=json.load(f)
    with (folder/"current_fork_native_route_differential.json").open(
            encoding="utf-8") as f:
        source=json.load(f)
    count=verify(data,source)
    def reject(name,change):
        f=copy.deepcopy(data)
        change(f)
        try:verify(f,source)
        except AssertionError:
            print("NATIVE_PRE_G_ADVERSARIAL_REJECT_PASS",name)
            return name
        raise AssertionError("forged Native pre-g evidence accepted: "+name)
    rejects=[
        reject("forged_g_return",lambda d:d["records"][0]["mutant"]
               ["real_g"].__setitem__("g_returned",12)),
        reject("forged_read_prevalue",lambda d:d["records"][0]["mutant"]
               ["real_g"].__setitem__("before_read",13)),
        reject("forged_read_tick",lambda d:d["records"][0]["mutant"]
               ["real_g"].__setitem__("step",-1)),
        reject("fake_intervention",lambda d:d["records"][0]["mutant"]
               ["real_g"].__setitem__("intervened",False)),
        reject("duplicate_case",lambda d:d["records"][1].__setitem__(
               "case",d["records"][0]["case"])),
        reject("forged_summary",lambda d:d.__setitem__(
               "final_semantic_changed_pairs",21)),
        reject("forged_source",lambda d:d.__setitem__("source_git_blob","0"*40))
    ]
    need(len(rejects)==7,"the pre-g tamper suite did not finish")
    output={"schema":"befunge-stage1-pre-g-audit-v1","input_pairs_verified":20,
            "tampered_reports_rejected":rejects,
            "final_semantic_changed_pairs":count,
            "final_stage1_accepted":False}
    with (folder/"native_pre_g_scratch_audit.json").open(
            "w",encoding="utf-8") as f:
        json.dump(output,f,indent=2,sort_keys=True)
        f.write("\n")
    print("NATIVE_PRE_G_20_PAIR_INDEPENDENT_7_TAMPER_PASS",
          "final_changes",count)
if __name__=="__main__":
    need(len(sys.argv)==2,"usage: NATIVE_EVIDENCE_DIR")
    main(sys.argv[1])
