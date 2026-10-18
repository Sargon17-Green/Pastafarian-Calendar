#!/usr/bin/env python3
"""Independent Stage1 audit: actual 17 Native executed feedback interventions.

Never evaluates calendar arithmetic. Reconstructs 17 original vs one-step
physical opcode intervention pairs and rejects falsified route/effect reports.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
LABELS=(
    "zero_equal","foundation_cross","forward_short","reverse_short",
    "mixed_small","positive_negative","negative_positive","large_values",
    "invalid_zero_sign","invalid_big_sign","epoch_forward_one",
    "epoch_reverse_one","recent_anchor_equal","recent_anchor_next",
    "foundation_neighbor_forward","foundation_neighbor_reverse",
    "invalid_target_zero_sign",
)
UPPER={
    "zero_equal","forward_short","reverse_short","positive_negative",
    "large_values","invalid_big_sign","epoch_forward_one",
    "epoch_reverse_one","recent_anchor_equal","recent_anchor_next",
    "invalid_target_zero_sign",
}
INVALID={"invalid_zero_sign","invalid_big_sign","invalid_target_zero_sign"}
STEP_LIMIT=210000

def need(ok,reason):
    if not ok:raise AssertionError(reason)

def sig(result):
    return (result["status"],result["remaining_ips"],result["output"])

def verify(d):
    need(d.get("schema")=="befunge-stage1-native-feedback-one-instruction-v1"
         and d.get("production_git_blob")==PIN
         and d.get("status")=="FINITE_NATIVE_FEEDBACK_GEOMETRY_COUNTERFACTUAL_STAGE1_OPEN"
         and d.get("source_trace_artifact_id")==11664135758
         and d.get("native_cases")==17
         and d.get("upper_cases")==11 and d.get("lower_cases")==6
         and d.get("real_native_program_executions")==34
         and d.get("real_native_control_mutant_pairs")==17
         and d.get("independent_native_oracle_cases")==17
         and d.get("immediate_direction_changes")==17
         and d.get("stage1_functional_acceptance") is False
         and d.get("stage1_geometric_acceptance") is False,
         "Native feedback source or bounded corpus altered")
    cases=d.get("records")
    need(isinstance(cases,list) and len(cases)==17
         and tuple(x.get("case") for x in cases)==LABELS,
         "17-case actual Native feedback corpus reordered or missing")
    effects=0
    for record in cases:
        label=record["case"]
        upper=label in UPPER
        target="upper_r" if upper else "lower_turn"
        cell=[957,1324] if upper else [951,1336]
        before_opcode="r" if upper else "]"
        after_opcode=" " if upper else "["
        valid=label not in INVALID
        output=record.get("reference_output")
        fields=record.get("input_fields")
        need(record.get("feedback_class")==target
             and record.get("valid") is valid
             and isinstance(fields,list) and len(fields)==4
             and all(type(x) is int for x in fields)
             and isinstance(output,list) and len(output)==7
             and all(type(x) is str for x in output)
             and (valid or output==["-1"]*7),
             "Native feedback case semantics/oracle reference invalid")
        c,m=record.get("control"),record.get("mutation")
        need(isinstance(c,dict) and isinstance(m,dict),
             "Native feedback lacks real control or mutant Program")
        for entry,mutated,byte in ((c,False,before_opcode),
                                   (m,True,after_opcode)):
            w=entry.get("witness")
            need(isinstance(w,dict)
                 and w.get("opcode")==before_opcode
                 and w.get("executed_opcode")==byte
                 and w.get("physical_cell")==cell
                 and type(w.get("tick")) is int and 1<w["tick"]<=STEP_LIMIT
                 and w.get("changed_one_instruction") is mutated
                 and w.get("restored_source_byte") is True
                 and isinstance(w.get("direction_before"),list)
                 and isinstance(w.get("direction_after"),list)
                 and len(w["direction_before"])==2
                 and len(w["direction_after"])==2
                 and all(type(x) is int for x in w["direction_before"]+
                             w["direction_after"])
                 and type(entry.get("steps")) is int
                 and w["tick"]<=entry["steps"]<=STEP_LIMIT+1
                 and entry.get("status") in ("normal","step_limit")
                 and type(entry.get("remaining_ips")) is int
                 and entry["remaining_ips"]>=0
                 and isinstance(entry.get("output"),list)
                 and all(type(x) is str for x in entry["output"]),
                 "Native intervention execution/source byte witness forged")
        cw,mw=c["witness"],m["witness"]
        need(cw["tick"]==mw["tick"]
             and cw["direction_before"]==mw["direction_before"]
             and cw["direction_after"]!=mw["direction_after"]
             and c["status"]=="normal" and c["remaining_ips"]==0
             and c["output"]==output,
             "Native intervention did not cause one-step vector divergence or changed sham")
        changed=sig(c)!=sig(m)
        need(record.get("final_output_or_termination_changed") is changed
             and record.get("actual_final_output_changed") is
                 (c["output"]!=m["output"]),
             "Native control-flow effect does not match genuine result")
        effects+=changed
    need(d.get("final_effect_cases")==effects,
         "Native feedback effects claim not supported by 17 measured pairs")
    return {"real_native_programs":34,
            "branch_a_feedback":11,"branch_b_feedback":6,
            "immediate_direction_changes":17,"final_effect_cases":effects}

def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(source)).encode("ascii")+
                     b"\0"+source).hexdigest()
    need(sha==PIN,"active native production source identity drifted")
    target=Path(folder)
    report=json.loads((target/"native_cycle_turn_interventions.json")
                      .read_text(encoding="utf-8"))
    summary=verify(report)
    print("NATIVE_FEEDBACK_17_PAIR_INDEPENDENT_AUDIT_PASS",json.dumps(summary))
    rejected=[]
    def attack(label,mutate):
        forged=copy.deepcopy(report)
        mutate(forged)
        try: verify(forged)
        except AssertionError:
            rejected.append(label)
            print("NATIVE_FEEDBACK_FALSIFIED_REPORT_REJECT_PASS",label)
            return
        raise AssertionError("forged Native feedback counterfactual accepted: "+label)
    attack("bad_source",lambda x:x.__setitem__("production_git_blob","0"*40))
    attack("missing_case",lambda x:x["records"].pop())
    attack("wrong_cohort",lambda x:x["records"][0].__setitem__("feedback_class","lower_turn"))
    attack("wrong_target",lambda x:x["records"][0]["mutation"]["witness"].__setitem__("physical_cell",[955,1324]))
    attack("changed_original_opcode",lambda x:x["records"][0]["mutation"]["witness"].__setitem__("opcode"," "))
    attack("unchanged_mutated_opcode",lambda x:x["records"][0]["mutation"]["witness"].__setitem__("executed_opcode","r"))
    attack("no_restore",lambda x:x["records"][0]["mutation"]["witness"].__setitem__("restored_source_byte",False))
    attack("wrong_tick",lambda x:x["records"][0]["mutation"]["witness"].__setitem__("tick",3))
    attack("no_vector_effect",lambda x:x["records"][0]["mutation"]["witness"].__setitem__(
        "direction_after",x["records"][0]["control"]["witness"]["direction_after"]))
    attack("changed_input",lambda x:x["records"][0]["input_fields"].pop())
    attack("broken_native_reference",lambda x:x["records"][0]["control"]["output"].__setitem__(0,"WRONG"))
    attack("false_final_effect",lambda x:x["records"][0].__setitem__(
        "final_output_or_termination_changed",
        not x["records"][0]["final_output_or_termination_changed"]))
    attack("false_count",lambda x:x.__setitem__("final_effect_cases",-1))
    attack("false_completion",lambda x:x.__setitem__("stage1_geometric_acceptance",True))
    need(len(rejected)==14,"Native feedback adversarial tests incomplete")
    (target/"native_cycle_turn_interventions_audit.json").write_text(
        json.dumps({"schema":"befunge-stage1-native-feedback-audit-v1",
                    "verified":summary,"adversarial_forged_reports_rejected":rejected,
                    "stage1_complete":False},indent=2,sort_keys=True)+"\n",
        encoding="utf-8")
    print("NATIVE_FEEDBACK_FOURTEEN_FALSIFIED_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"usage: Native counterfactual evidence directory")
    main(sys.argv[1])
