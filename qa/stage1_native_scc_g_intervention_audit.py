#!/usr/bin/env python3
"""Independent fail-closed audit of 9 genuine SCC p/g interventions.

No computation of calendar values in Python. Checks exact trace-pinned
physical location and order, active actual stack g result, native-only
reference parity of sham, status and measured final-effect classification.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
WITNESSES=[
    ("foundation_cross",23083,23246,-2,True),
    ("forward_short",11399,11562,1,True),
    ("reverse_short",11399,11562,2,True),
    ("mixed_small",11323,11486,-1,True),
    ("positive_negative",24839,25002,9,True),
    ("negative_positive",24763,24926,-1,True),
    ("large_values",75239,75402,8,True),
    ("recent_anchor_next",21479,21642,9,True),
    ("invalid_big_sign",13067,13230,0,False),
]
def need(value,why):
    if not value: raise AssertionError(why)

def sig(row):
    return (row["status"],row["remaining_ips"],row["output"])

def validate(report):
    need(report.get("schema")=="befunge-stage1-native-scc-live-g-intervention-v1"
         and report.get("source_git_blob")==PIN
         and report.get("status")=="FINITE_NATIVE_CAUSALITY_OBSERVATION_STAGE1_OPEN"
         and report.get("source_trace_artifact_id")==11664135758
         and report.get("physical_cell")==[37,1700]
         and report.get("writer")==[1249,1050]
         and report.get("reader")==[575,1164]
         and report.get("real_native_intervention_pairs")==9
         and report.get("real_native_program_executions")==18
         and report.get("valid_cases")==8
         and report.get("invalid_cases")==1
         and report.get("native_oracle_invocations")==24
         and report.get("causal_g_stack_changes")==9
         and report.get("stage1_functional_acceptance") is False
         and report.get("stage1_geometry_acceptance") is False,
         "Native SCC intervention source, scope or Stage1 status falsified")
    rows=report.get("records")
    need(isinstance(rows,list) and len(rows)==9,
         "Native SCC real intervention matrix incomplete")
    total=0
    for row,expected in zip(rows,WITNESSES):
        label,wt,rt,value,valid=expected
        need(row.get("case")==label and row.get("valid") is valid
             and row.get("native_writer_tick")==wt
             and row.get("native_reader_tick")==rt
             and rt-wt==163
             and row.get("cell_before")==value
             and row.get("cell_mutated")==value+1,
             "physical p-to-g event, branch or exact Native chronology forged")
        fields=row.get("input_fields")
        output=row.get("expected_reference")
        need(isinstance(fields,list) and len(fields)==4
             and all(type(x) is int for x in fields)
             and isinstance(output,list) and len(output)==7
             and all(type(x) is str for x in output)
             and (valid or output==["-1"]*7),
             "native test input or reference vector invalid")
        control=row.get("control")
        mutated=row.get("intervention")
        need(isinstance(control,dict) and isinstance(mutated,dict),
             "native controls absent")
        for record,expected_g,is_mutant in ((control,value,False),
                                            (mutated,value+1,True)):
            need(record.get("actual_g_return")==expected_g
                 and record.get("one_cell_intervention") is is_mutant
                 and record.get("writer_executed") is True
                 and record.get("reader_executed") is True
                 and type(record.get("steps")) is int
                 and rt<=record["steps"]<=250001
                 and record.get("status") in ("normal","step_limit")
                 and type(record.get("remaining_ips")) is int
                 and record["remaining_ips"]>=0
                 and isinstance(record.get("output"),list)
                 and all(type(x) is str for x in record["output"]),
                 "actual native g stack value or instrumented execution forged")
        need(control["status"]=="normal"
             and control["remaining_ips"]==0
             and control["output"]==output,
             "native full seven-field control not independent reference")
        effect=sig(control)!=sig(mutated)
        need(row.get("downstream_output_or_termination_changed") is effect,
             "Native final-output/termination causality misrepresented")
        total+=effect
    need(report.get("downstream_final_effects")==total,
         "miscounted actual observed native output effects")
    return {"pairs":9,"real_native_programs":18,"g_stack_changes":9,
            "output_or_termination_effects":total}

def main(path):
    data=Path("src/interleaved_work_counts.b98").read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(data)).encode("ascii")+
                      b"\0"+data).hexdigest()
    need(blob==PIN,"pinned Befunge production source changed")
    record=json.loads((Path(path)/"native_scc_g_interventions.json")
                      .read_text(encoding="utf-8"))
    summary=validate(record)
    print("NATIVE_SCC_G_INTERVENTION_INDEPENDENT_AUDIT_PASS",summary)
    attacks=[]
    def reject(label,fn):
        bad=copy.deepcopy(record)
        fn(bad)
        try:validate(bad)
        except AssertionError:
            print("NATIVE_SCC_G_INTERVENTION_TAMPER_REJECT_PASS",label)
            attacks.append(label)
            return
        raise AssertionError("Native SCC falsified evidence accepted: "+label)
    reject("source_blob",lambda d:d.__setitem__("source_git_blob","0"*40))
    reject("missing_run",lambda d:d["records"].pop())
    reject("shuffled_case",lambda d:d["records"][1].__setitem__("case","reverse_short"))
    reject("wrong_cell",lambda d:d.__setitem__("physical_cell",[38,1700]))
    reject("wrong_p_tick",lambda d:d["records"][0].__setitem__("native_writer_tick",23082))
    reject("wrong_g_tick",lambda d:d["records"][0].__setitem__("native_reader_tick",23245))
    reject("unchanged_g_stack",lambda d:d["records"][0]["intervention"].__setitem__(
        "actual_g_return",-2))
    reject("sham_changes_output",lambda d:d["records"][0]["control"]["output"].__setitem__(0,"forged"))
    reject("sham_was_modified",lambda d:d["records"][0]["control"].__setitem__("one_cell_intervention",True))
    reject("forgot_g",lambda d:d["records"][0]["intervention"].__setitem__("reader_executed",False))
    reject("false_effect",lambda d:d["records"][0].__setitem__("downstream_output_or_termination_changed",
        not d["records"][0]["downstream_output_or_termination_changed"]))
    reject("false_effect_count",lambda d:d.__setitem__("downstream_final_effects",-1))
    reject("false_geometry_acceptance",lambda d:d.__setitem__("stage1_geometry_acceptance",True))
    reject("false_functional_acceptance",lambda d:d.__setitem__("stage1_functional_acceptance",True))
    need(len(attacks)==14,"adversarial real-g controls missing")
    output={"schema":"befunge-stage1-native-scc-live-g-intervention-audit-v1",
            "verified":summary,"negative_reports_rejected":attacks,
            "stage1_completion":False}
    (Path(path)/"native_scc_g_interventions_audit.json").write_text(
        json.dumps(output,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_SCC_REAL_G_FOURTEEN_HOSTILE_REPORTS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: native SCC intervention evidence folder")
    main(sys.argv[1])
