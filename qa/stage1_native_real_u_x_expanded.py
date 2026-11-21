#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Expand real Native u->x two-stack-cell causal mediation to six new valid cases.

Case selection is frozen from independently retained 17 native full-route
traces: only cases with actual (954,1328) u and (950,1335) x, including
two large sign/magnitude families, are eligible for this follow-up.
No Python calendar arithmetic. All expected outputs come from the three
original independent BF98 reference programs via diverse_geometry.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_native_real_u_x_mediation as n
import stage1_native_diverse_geometry as refs

ROOT="/expanded-u-x"
FROZEN=(
    ("reverse_short",10117,19713),
    ("epoch_forward_one",10117,19713),
    ("epoch_reverse_one",10117,19713),
    ("recent_anchor_equal",20197,43749),
    ("positive_negative",23557,51761),
    ("large_values",73957,171941),
)
LIMIT=260000
def check(value,why):
    if not value:raise AssertionError(why)
def success(t,ref):
    return t["status"]=="normal" and t["remaining_ips"]==0 and t["output"]==ref

def main():
    check(os.path.isdir(ROOT),"Native u-x expanded evidence destination not mounted")
    raw_source=open(n.SRC,"rb").read()
    sha=hashlib.sha1("blob %d\0%s"%(len(raw_source),raw_source)).hexdigest()
    check(sha==n.PIN,"Native BF98 exact source identity changed")
    check(n.U==(954,1328) and n.X==(950,1335),
          "real Native u-x coordinates not preserved")
    n.BOUND=LIMIT
    names=dict((name,(fields,valid)) for name,fields,valid in refs.CASES)
    records=[]
    for name,u_tick,control_steps in FROZEN:
        fields,valid=names[name]
        check(valid,"invalid case selected as expanded Native control")
        raw=" ".join(map(str,fields))+"\n"
        expected=refs.expected_for(*fields)
        check(len(expected)==7 and expected!=["-1"]*7,
              "real independent BF98 numerical reference not seven valid words")
        control=n.run(raw_source,raw,0,"none")
        check(success(control,expected)
              and control["steps"]==control_steps
              and control["u"]["tick"]==u_tick
              and control["x"]["tick"]==u_tick+99
              and control["x"]["pre_actual"]==[["1","-1","0"]],
              "original Native BF98 u-x case departed from independently "
              "recorded 17-trace case route or reference")
        counterfactuals=[]
        for delta in (-1,-2):
            a=n.run(raw_source,raw,delta,"none")
            b=n.run(raw_source,raw,delta,"direction")
            c=n.run(raw_source,raw,delta,"full")
            for run in (a,b,c):
                check(run["u"]["tick"]==u_tick and
                      run["x"]["tick"]==u_tick+99 and
                      run["x"]["pre_actual"]==
                        [[str(1+delta),str(-1+delta),"0"]],
                      "actual original BF98 u->x two-channel mediation timing/data drift")
            check(a["x"]["post_delta"]==[-1+delta,0]
                  and b["x"]["post_delta"]==[-1,0]
                  and c["x"]["post_delta"]==[-1,0],
                  "native executed x vector does not respond to changed operand")
            check(a["status"]=="step-limit" and a["steps"]==LIMIT+1,
                  "expanded original u mutant failed to exhibit bounded deviation")
            check(success(c,expected) and c["steps"]==control_steps,
                  "expanded full two-stack-cell restoration did not recover "
                  "Native independent BF98 reference and original step count")
            entry={"delta":delta,"unrescued":a,
                   "direction_only":b,"full_x_input":c,
                   "direction_only_recovers_reference":success(b,expected),
                   "direction_only_terminated_normally":
                      b["status"]=="normal" and b["remaining_ips"]==0,
                   "both_channels_recovered":True}
            counterfactuals.append(entry)
            print("NATIVE_EXPANDED_U_X_MEDIATION_MEASURED",name,"delta",delta,
                  "baseline_steps",control_steps,
                  "direction_only_reference",entry["direction_only_recovers_reference"],
                  "direction_only_status",b["status"],
                  "both_channels_steps",c["steps"])
            sys.stdout.flush()
        records.append({"case":name,"input_fields":[str(v) for v in fields],
                        "u_tick":u_tick,"normal_steps":control_steps,
                        "reference_7":expected,"control":control,
                        "counterfactuals":counterfactuals})
    d={"schema":"befunge-stage1-expanded-six-case-native-u-x-mediation-v1",
       "scope":"SIX_ADDITIONAL_VALID_INPUTS_WITH_FROZEN_EXECUTED_U_X_TRACE_WITNESSES",
       "source_git_blob":n.PIN,
       "reference_frozen_native_17_trace_cases":list(FROZEN),
       "native_programs_executed":42,"independent_native_references":6,
       "last_completed_stage":0,"stage1_complete":False,
       "automatic_promotion":False,
       "geometric_spaghetti_qa_pass":False,
       "production_modified":False,"records":records}
    with open(ROOT+"/expanded_u_x_native_evidence.json","wb") as f:
        f.write(json.dumps(d,indent=2,sort_keys=True)+"\n")
    print("NATIVE_BF98_EXPANDED_U_X_TWELVE_FULL_RESCUES_42_EXECUTIONS_PASS")
    print("LAST_COMPLETED_STAGE=0 GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":main()
