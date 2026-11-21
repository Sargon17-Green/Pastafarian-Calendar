#!/usr/bin/env python3
"""Fail-closed Native BF98 clean-vs-faulted four-live ownership comparison.

Two independently measured, original-source-pinned Native PyFunge cohorts
must agree for all 32 faulted/recovered/healthy program invocations: seven
output words, IP ticks, actual Funge-space gets and puts. The source code
is unchanged; Python does not compute any calendar result. This is finite
Stage-1 QA, not final Stage-1 semantic ownership certification.

This auditor intentionally uses explicit exceptions, never Python assert:
python -O must not disable any of its comparisons. Eight hostile mutations
are *individually valid* to the originating cohort auditor and must be
rejected solely by the cross-cohort comparison.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path
import stage1_native_four_live_programs_audit as clean_audit
import stage1_native_four_live_p_fault_recovery_audit as fault_audit

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"

def need(ok,message):
    if not ok:
        raise AssertionError(message)

def sig(member,faulted):
    return (member["steps"] if faulted else member["ticks"],
            member["native_get"],member["native_put"],
            tuple(member["output"]))

def verify(clean,fault):
    clean_audit.verify(clean)
    fault_audit.verify(fault)
    need(clean.get("source_git_blob")==fault.get("source_git_blob")==PIN
         and clean.get("stage1_final_acceptance") is False
         and fault.get("stage1_final_acceptance") is False
         and clean.get("production_modified") is False
         and fault.get("production_modified") is False,
         "different production source or false Stage-1 closure")
    expected={x for group in clean_audit.GROUPS for x in group}
    need(len(expected)==19,"pinned clean 4-live input corpus changed")
    reference={}
    repeats={}
    for row in clean["records"]:
        for member in row["programs"]:
            label=member["label"]
            measured=sig(member,False)
            need(label not in reference or reference[label]==measured,
                 "clean four-live input signature changed by peers")
            reference[label]=measured
            repeats[label]=repeats.get(label,0)+1
    need(set(reference)==expected and
         all(repeats[k]>=2 for k in expected),
         "clean four-live repeated Native input coverage incomplete")
    comparisons=0
    fault_labels=set()
    for row in fault["records"]:
        for member in row["programs"]:
            label=member["label"]
            fault_labels.add(label)
            need(label in reference,
                 "faulted Native input absent from independently run clean cohort")
            need(sig(member,True)==reference[label],
                 "Native BF98 fault/reset changed IP steps or memory get/put/output: "+label)
            need(member["output"]==clean["oracle"][label]==fault["oracle"][label],
                 "independent Native seven-word oracles disagree: "+label)
            comparisons+=1
    need(comparisons==32 and len(fault["records"])==8
         and fault_labels=={x for row in fault_audit.SCENARIOS for x in row[0]},
         "all 32 Native fault/clean program identities not compared")
    return {"native_clean_four_live_programs":56,
            "native_faulted_or_healthy_programs":32,
            "exact_cross_cohort_signature_comparisons":comparisons,
            "seven_output_fields_compared":7*comparisons,
            "clean_input_signatures":len(reference),
            "fault_input_signatures":len(fault_labels),
            "native_ip_get_put_output_equivalent":True,
            "stage1_final_acceptance":False}

def change_output(report,label):
    report["oracle"][label][0]="CROSS_ONLY_FORGED_WORD"
    for row in report["records"]:
        for member in row["programs"]:
            if member["label"]==label:
                member["output"][0]="CROSS_ONLY_FORGED_WORD"

def change_counter(report,label,field,second_field=None):
    changed=0
    for row in report["records"]:
        for member in row["programs"]:
            if member["label"]==label:
                member[field]+=1
                if second_field is not None:
                    member[second_field]+=1
                changed+=1
    need(changed>=2,"hostile cross-only input not repeated under both schedules")

def independent_negative_controls(clean,fault):
    # Every mutation must pass its original single-cohort auditor. Therefore
    # only the actual cross-cohort evidence binding can reject it.
    attacks=(
        ("clean_valid_oracle",0,lambda x:change_output(x,"v0")),
        ("fault_valid_oracle",1,lambda x:change_output(x,"v0")),
        ("clean_native_ticks",0,lambda x:change_counter(x,"v0","ticks")),
        ("fault_native_ticks",1,lambda x:change_counter(x,"v0","steps")),
        ("clean_native_gets",0,lambda x:change_counter(x,"v0","native_get")),
        ("fault_native_gets",1,lambda x:change_counter(x,"v0","native_get")),
        ("clean_native_puts",0,lambda x:change_counter(x,"v0","native_put","native_direct_p")),
        ("fault_native_puts",1,lambda x:change_counter(x,"v0","native_put","native_direct_p")),
    )
    rejected=[]
    for name,side,mutate in attacks:
        a=copy.deepcopy(clean)
        b=copy.deepcopy(fault)
        mutate(a if side==0 else b)
        # Crucial control: not a single-cohort rejection.
        clean_audit.verify(a)
        fault_audit.verify(b)
        try:
            verify(a,b)
        except AssertionError:
            rejected.append(name)
        else:
            raise AssertionError("cross-cohort accepted individually valid forgery: "+name)
    need(len(rejected)==8,"eight cross-only hostile report mutations incomplete")
    return rejected

def main(clean_dir,fault_dir):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    actual=hashlib.sha1(b"blob "+str(len(source)).encode("ascii")
                        +b"\0"+source).hexdigest()
    need(actual==PIN,"production BF98 source Git blob changed")
    c=Path(clean_dir)
    f=Path(fault_dir)
    clean=json.loads((c/"native_four_live_programs.json").read_text("utf-8"))
    fault=json.loads((f/"native_quad_fault_recovery.json").read_text("utf-8"))
    result=verify(clean,fault)
    rejected=independent_negative_controls(clean,fault)
    print("NATIVE_FOUR_FAULT_VS_CLEAN_32_EXACT_SIGNATURES_PASS_STAGE1_OPEN",
          json.dumps(result,sort_keys=True))
    print("NATIVE_FOUR_CROSS_ONLY_EIGHT_INDIVIDUALLY_VALID_FORGERIES_REJECTED",
          ",".join(rejected))
    print("PYTHON_OPTIMIZATION_SAFE_CROSS_COHORT_AUDIT_PASS",
          "optimized" if not __debug__ else "normal")

if __name__=="__main__":
    need(len(sys.argv)==3,"usage: cross_audit.py CLEAN_NATIVE_DIR FAULT_NATIVE_DIR")
    main(sys.argv[1],sys.argv[2])
