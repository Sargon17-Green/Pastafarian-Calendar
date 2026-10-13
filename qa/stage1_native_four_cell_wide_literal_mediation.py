#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only 32 wide-input Native first literal zero/next-step stack rescue.

All outputs come from real PyFunge four-cell candidate and three independent
Befunge-98 references. Python only dispatches and instruments Native runs.
No production changes or universal Stage-1 acceptance.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide
import stage1_native_current_fork_route_differential as fork
import stage1_native_lower_feedback_semantic_candidate as four
import stage1_native_four_cell_grid_literal_intervention as counterfactual
import stage1_native_four_cell_grid_literal_stack_rescue as mediation

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
ROOT="/four-cell-wide-mediation"
LIMIT=750000

def need(ok,reason):
    if not ok:raise AssertionError(reason)

def compact(z):
    keys=("status","steps","remaining_ips","output",
          "native_lower_literal_visits","native_live_literal_edits",
          "immediate_restorations","restored_source_byte",
          "final_source_byte","first_literal")
    return dict((k,z[k]) for k in keys)

def main():
    need(os.path.isdir(ROOT),"isolated wide BF98 mediation volume missing")
    original=open(native.SOURCE,"rb").read()
    need(four.git_blob(original)==BASE,"pinned Native production source drifted")
    program=four.candidate_bytes(original)
    need(four.git_blob(program)==PIN,"pinned four-cell test-only candidate drifted")
    counterfactual.BOUND=LIMIT
    mediation.BOUND=LIMIT
    lookup=dict((name,(fields,valid)) for name,fields,valid in
                list(native.CASES)+list(wide.CASES))
    labels=tuple(fork.CASE_NAMES)
    need(len(labels)==32 and len(set(labels))==32 and len(lookup)==39,
         "wide 32 valid BF98 input roster changed")
    rows=[]
    for i,name in enumerate(labels):
        fields,valid=lookup[name]
        need(valid and len(fields)==4,"invalid input in wide BF98 reference corpus")
        raw=" ".join(map(str,fields))+"\n"
        expected=native.expected_for(*fields)
        control=counterfactual.run(program,raw,False)
        mutant=counterfactual.run(program,raw,True)
        rescued=mediation.rescue_native(program,raw)
        visits=control["native_lower_literal_visits"]
        hit=int(visits>0)
        changed=(mutant["status"]!="normal" or mutant["remaining_ips"]!=0
                 or mutant["output"]!=expected)
        need(len(expected)==7 and control["status"]=="normal" and
             control["remaining_ips"]==0 and control["output"]==expected,
             "Native wide four-cell control/reference parity failed "+name)
        need(control["native_live_literal_edits"]==0 and
             mutant["native_live_literal_edits"]==hit and
             mutant["immediate_restorations"]==hit and
             mutant["restored_source_byte"]==(49 if hit else None),
             "actual Native wide literal one-step mutation missing "+name)
        need(rescued["status"]=="normal" and rescued["remaining_ips"]==0 and
             rescued["output"]==expected and
             rescued["lower_literal_visits"]==visits and
             rescued["edited_literal_steps"]==hit and
             rescued["repaired_toss_values"]==hit,
             "Native wide next-opcode stack repair not successful "+name)
        if hit:
            lit=rescued["actual_literal"]
            repair=rescued["actual_stack_rescue"]
            need(type(lit) is dict and type(repair) is dict and
                 lit["pushed"]==0 and lit["restored_physical_source_byte"]==49 and
                 repair["tick"]==lit["tick"]+1 and
                 repair["top_before"]=="0" and repair["top_after"]=="1" and
                 repair["other_stack_values_unchanged"] is True and
                 repair["intervened_source_byte_before_next"]==49,
                 "wide Native physical literal/TOSS causal chain incomplete "+name)
        else:
            need(mutant["status"]=="normal" and mutant["remaining_ips"]==0 and
                 mutant["output"]==expected and
                 rescued["actual_literal"] is None and
                 rescued["actual_stack_rescue"] is None,
                 "unreached wide Native literal altered another route "+name)
        rows.append(dict(index=i,case=name,input_fields=list(fields),
           input_sha256=hashlib.sha256(raw.encode("ascii")).hexdigest(),
           reference_output=expected,control=compact(control),
           zero_intervention=compact(mutant),stack_rescue=rescued,
           literal_reached=bool(hit),causal_effect=bool(changed),
           next_step_toss_rescued=bool(hit)))
        print("NATIVE_WIDE_LITERAL_STACK_CASE",i+1,"of",len(labels),name,
              "visited",visits,"changed",int(changed),"rescue",hit)
        sys.stdout.flush()
    reached=sum(z["literal_reached"] for z in rows)
    causal=sum(z["causal_effect"] for z in rows)
    need(0<reached<len(rows),"wide BF98 diagnostic must exercise both routes")
    report=dict(
       schema="befunge-stage1-four-cell-wide-literal-stack-v1",
       status="FINITE_WIDE_NATIVE_MEDIATION_STAGE1_OPEN",
       production_blob=BASE,candidate_blob=PIN,
       sampled_valid_cases=32,control_native_executions=32,
       intervention_native_executions=32,rescue_native_executions=32,
       native_reference_executions=96,total_native_executions=192,
       native_step_budget=LIMIT,visited_cases=reached,
       unvisited_cases=32-reached,causal_effect_cases=causal,
       restored_by_one_toss_cases=sum(z["next_step_toss_rescued"] for z in rows),
       source_modified=False,stage1_complete=False,stage2_started=False,
       records=rows)
    with open(ROOT+"/native_wide_literal_mediation_32.json","wb") as f:
        f.write((json.dumps(report,sort_keys=True,indent=2)+"\n").encode("ascii"))
    print("NATIVE_FOUR_CELL_WIDE_32_NATIVE_STACK_RESCUES_PASS",
          "visited",reached,"causal",causal)
    print("LAST_COMPLETED_STAGE=0; GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":main()
