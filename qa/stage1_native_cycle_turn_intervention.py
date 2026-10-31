#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1: live, ONE-INSTRUCTION Native cycle-routing intervention.

A 17-case, two-route Native PyFunge control/mutant experiment. Before real
execution of the actually observed feedback opcode, replace JUST that one
Funge-space instruction cell, execute the one Native instruction, and restore
the byte immediately. No persistent source edits and NO Python calendar math.

Upper 2-cell SCC: r at (957,1324) -> space, reversing a real feedback vector.
Lower 18-cell SCC: ] at (951,1336) -> [, reversing its real turn sense.
The original native input/output is checked using independent test-only
Befunge-98 reference programs. Mutation effects are MEASURED, not assumed.
"""
from __future__ import print_function
import hashlib
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as suite

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT="/turn-cycle/native_cycle_turn_interventions.json"
LIMIT=210000
UPPER=(957,1324)
LOWER=(951,1336)
UPPER_LABELS=set((
    "zero_equal","forward_short","reverse_short","positive_negative",
    "large_values","invalid_big_sign","epoch_forward_one",
    "epoch_reverse_one","recent_anchor_equal","recent_anchor_next",
    "invalid_target_zero_sign",
))
class Bound(Exception): pass

def require(ok,msg):
    if not ok:raise AssertionError(msg)

def git_blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def run_native(source,raw,site,mutate):
    stdout=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=stdout))
    p.load_code(source)
    p.create_ip()
    require(len(p.ips)==1,"live native cycle must start with one IP")
    target=UPPER if site=="upper_r" else LOWER
    original=ord("r") if site=="upper_r" else ord("]")
    replacement=ord(" ") if site=="upper_r" else ord("[")
    point=p.ips[0].position.__class__(target)
    require(int(p.space.get(point))==original,
            "exact opcode at Native feedback cell changed")
    prior=p.execute_step
    steps=[0]
    visit=[None]
    gate=[0]
    def step(self):
        steps[0]+=1
        if steps[0]>LIMIT:
            raise Bound("bounded Native one-instruction feedback intervention")
        if self.ips:
            require(len(self.ips)==1,"Unexpected second IP in one-cycle trial")
            ip=self.ips[0]
            if tuple(ip.position)==target and gate[0]==0:
                require(int(self.space.get(point))==original,
                        "Native feedback opcode not present on first visit")
                before=tuple(ip.delta)
                gate[0]=1
                if mutate:
                    self.space.put(point,replacement)
                try:
                    result=prior()
                finally:
                    if mutate:
                        self.space.put(point,original)
                require(int(self.space.get(point))==original,
                        "real opcode not restored after one-instruction intervention")
                visit[0]={"opcode":chr(original),
                          "executed_opcode":chr(replacement if mutate else original),
                          "physical_cell":list(target),
                          "tick":steps[0],
                          "direction_before":list(before),
                          "direction_after":list(ip.delta),
                          "changed_one_instruction":bool(mutate),
                          "restored_source_byte":True}
                return result
        return prior()
    p.execute_step=step.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except Bound:status="step_limit"
    finally:del p.execute_step
    require(gate[0]==1 and visit[0] is not None,
            "actual live Native route feedback opcode never executed")
    return {"status":status,"steps":steps[0],
            "remaining_ips":len(p.ips),"output":stdout.getvalue().split(),
            "witness":visit[0]}

def sig(r):
    return (r["status"],r["remaining_ips"],r["output"])

def main():
    require(os.path.isdir("/turn-cycle"),"missing evidence mount")
    source=open("src/interleaved_work_counts.b98","rb").read()
    require(git_blob(source)==PIN,"pinned QA Native source changed")
    records=[]
    for label,fields,valid in suite.CASES:
        site="upper_r" if label in UPPER_LABELS else "lower_turn"
        raw=" ".join(map(str,fields))+"\n"
        native_ref=(suite.expected_for(*fields) if valid else ["-1"]*7)
        require(len(native_ref)==7,"independent Native oracle malformed")
        control=run_native(source,raw,site,False)
        mutant=run_native(source,raw,site,True)
        require(control["status"]=="normal" and control["remaining_ips"]==0
                and control["output"]==native_ref,
                "original Native routing differs from independent Befunge reference: "+label)
        cw,mw=control["witness"],mutant["witness"]
        require(cw["physical_cell"]==mw["physical_cell"]
                and cw["tick"]==mw["tick"]
                and cw["direction_before"]==mw["direction_before"]
                and cw["direction_after"]!=mw["direction_after"]
                and cw["changed_one_instruction"] is False
                and mw["changed_one_instruction"] is True
                and cw["restored_source_byte"] is True
                and mw["restored_source_byte"] is True,
                "Native feedback intervention did not cause exact first-turn divergence")
        changed=sig(control)!=sig(mutant)
        row={"case":label,"input_fields":list(fields),"valid":bool(valid),
             "feedback_class":site,"reference_output":native_ref,
             "control":control,"mutation":mutant,
             "actual_final_output_changed":control["output"]!=mutant["output"],
             "final_output_or_termination_changed":changed}
        records.append(row)
        print("NATIVE_FEEDBACK_SINGLE_INSTRUCTION_INTERVENTION_PASS",
              label,site,"native_tick",cw["tick"],
              "output_or_termination_changed",changed,
              "mutant_status",mutant["status"])
        sys.stdout.flush()
    upper=sum(row["feedback_class"]=="upper_r" for row in records)
    lower=len(records)-upper
    effects=sum(row["final_output_or_termination_changed"] for row in records)
    require(upper==11 and lower==6,"Native upper/lower feedback cohort changed")
    report={"schema":"befunge-stage1-native-feedback-one-instruction-v1",
            "production_git_blob":PIN,
            "status":"FINITE_NATIVE_FEEDBACK_GEOMETRY_COUNTERFACTUAL_STAGE1_OPEN",
            "source_trace_artifact_id":11664135758,
            "native_cases":17,"upper_cases":upper,"lower_cases":lower,
            "real_native_program_executions":34,
            "real_native_control_mutant_pairs":17,
            "independent_native_oracle_cases":17,
            "immediate_direction_changes":17,
            "final_effect_cases":effects,
            "stage1_functional_acceptance":False,
            "stage1_geometric_acceptance":False,
            "records":records}
    with open(OUT,"wb") as stream:
        stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_FEEDBACK_17_REAL_DIRECTED_ROUTE_COUNTERFACTUALS_PASS",
          "immediate_divergence",17,"output_or_termination_effects",effects)
    print("FULL_GEOMETRIC_SPAGHETTI_QA_PASS=NO LAST_COMPLETED_STAGE=0")

if __name__=="__main__":main()
