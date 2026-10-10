#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1: actually execute both routes of upper/lower | in four-cell candidate.

Native PyFunge 0.5-rc2 executes 32 valid input controls + 32 single operand
inversions at EXACT (951,1335). The original source is pinned read-only;
generate candidate with only the original four physical changes. Referenced
calendar outputs come ONLY from genuine independent Befunge-98 programs.
Record downstream causal output vs inert effects without assuming outcomes.
Physical p/g writes, shared route and whole-stack/IP context are measured
by the pre-existing pinned native fork observer. No production promotion.
"""
from __future__ import print_function
import json,os,sys
import stage1_native_diverse_geometry as suite
import stage1_native_reflective_candidate_domain_matrix as wide
import stage1_native_current_fork_route_differential as fork
import stage1_native_lower_feedback_semantic_candidate as candidate

OUT="/four-cell-fork"
REPORT=OUT+"/four_cell_fork_32_control_mutant.json"
SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE_PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"

def check(ok,why):
    if not ok:raise AssertionError(why)

def compact_entry(obj):
    return {
      "status":obj["status"],"steps":obj["steps"],
      "remaining_ips":obj["remaining_ips"],"output":obj["output"],
      "gate_events":obj["gates"],
      "total_p_writes":obj["observed_native_p_writes"],
      "total_g_reads":len(obj["native_g_reads_raw"]),
      "scratch_value":obj["final_scratch_value"],
      "first_5_motion":[list(row) for row in obj["route"][:5]]
    }

def main():
    check(os.path.isdir(OUT),"Native fork candidate QA destination missing")
    original=open(SOURCE,"rb").read()
    check(candidate.git_blob(original)==PIN,"original BF98 Native source changed")
    candidate_code=candidate.candidate_bytes(original)
    check(candidate.git_blob(candidate_code)==CANDIDATE_PIN,
          "candidate Native source is not exact four physical edits")
    with open(OUT+"/four_cell_candidate.b98","wb") as p:p.write(candidate_code)
    book=dict((a,(b,c)) for a,b,c in list(suite.CASES)+list(wide.CASES))
    labels=tuple(fork.CASE_NAMES)
    check(len(labels)==32 and len(set(labels))==32,
          "Native current fork 32 valid-input matrix no longer frozen")
    report=[]
    for label in labels:
        fields,valid=book[label]
        check(valid,"fork counterfactual requires original valid native input")
        raw=" ".join(map(str,fields))+"\n"
        expected=suite.expected_for(*fields)
        check(len(expected)==7 and expected!=["-1"]*7,
              "real independent Befunge reference invalid "+label)
        control=fork.native_run(candidate_code,raw,False)
        forced=fork.native_run(candidate_code,raw,True)
        check(control["status"]=="normal" and control["remaining_ips"]==0
              and control["output"]==expected and
              len(control["gates"])==1 and len(forced["gates"])==1,
              "native candidate fork natural output/reference or live | mismatch "+
              label)
        ga,gb=control["gates"][0],forced["gates"][0]
        check(ga["step"]==gb["step"] and
              ga["original"]==ga["executed"]==gb["original"] and
              gb["executed"]==1-ga["executed"] and
              ga["depth"]==gb["depth"],
              "Native candidate fork did not invert exactly one real operand "+label)
        check(len(control["route"])>=5 and len(forced["route"])>=5 and
              control["route"][0][:4]!=forced["route"][0][:4] and
              control["route"][0][3]==-forced["route"][0][3] and
              control["route"][0][3]!=0,
              "Native candidate actual first branch motion not opposite "+label)
        # Compare executed directed Funge-space motion (x,y,dx,dy), NOT
        # TOSS depth. This candidate deliberately changes stack contents
        # and sometimes depth at an identical physical rejoin: including
        # stack depth in geometry would incorrectly reject the very
        # causal divergence this experiment is designed to measure.
        route_motion_a=[tuple(z[:4]) for z in control["route"]]
        route_motion_b=[tuple(z[:4]) for z in forced["route"]]
        joined=fork.common_subpath(route_motion_a,route_motion_b,5)
        check(joined is not None,
              "real Native opposite fork routes did not rejoin in 512 trace steps "+
              label)
        ia,ib=joined["original_offset"],joined["mutant_offset"]
        change=(forced["status"]!="normal" or forced["remaining_ips"]!=0
                or forced["output"]!=expected)
        stack_equal=[]
        context_equal=[]
        memory_equal=[]
        frames_a=[];frames_b=[];memory_a=[];memory_b=[];context_a=[];context_b=[]
        for k in range(5):
            idx_a,idx_b=ia+k,ib+k
            a=control["post_frames"][idx_a];b=forced["post_frames"][idx_b]
            x=control["post_modified_p_cells"][idx_a]
            y=forced["post_modified_p_cells"][idx_b]
            ca=control["post_ip_context"][idx_a]
            cb=forced["post_ip_context"][idx_b]
            frames_a.append(a);frames_b.append(b)
            memory_a.append(x);memory_b.append(y)
            context_a.append(ca);context_b.append(cb)
            stack_equal.append(a==b);context_equal.append(ca==cb)
            memory_equal.append(x==y)
        row={
          "label":label,"fields":[str(z) for z in fields],
          "reference_7":expected,
          "control":compact_entry(control),"forced":compact_entry(forced),
          "natural_nonzero":ga["original"],
          "forced_nonzero":gb["executed"],
          "first_shared_motion_offsets":[ia,ib],
          # Complete Native directed traces allow independent replay of the
          # observed five-event fork rejoin, not just a claimed witness.
          "complete_motion_control":[list(z) for z in route_motion_a],
          "complete_motion_forced":[list(z) for z in route_motion_b],
          "five_shared_motion":[list(z) for z in joined["real_motion_sample"]],
          "five_frames_control":frames_a,"five_frames_forced":frames_b,
          "five_p_mutations_control":memory_a,
          "five_p_mutations_forced":memory_b,
          "five_context_control":context_a,
          "five_context_forced":context_b,
          "five_equal_frames":stack_equal,
          "five_equal_p_mutations":memory_equal,
          "five_equal_context":context_equal,
          "changed_final_output_or_termination":change,
          "changed_actual_seven_output":forced["output"]!=expected,
        }
        report.append(row)
        print("NATIVE_QA_FOUR_CELL_32_VALID_FORK_MEASURED",
              label,"natural_operand",ga["executed"],
              "output_causal",change,
              "native_rejoin",ia,ib,
              "all_frames_equal",all(stack_equal),
              "all_p_cells_equal",all(memory_equal))
        sys.stdout.flush()
    zeros=[row for row in report if row["natural_nonzero"]==0]
    ones=[row for row in report if row["natural_nonzero"]==1]
    check(len(report)==32 and len(zeros)==12 and len(ones)==20,
          "Native fork actual zero/nonzero distribution changed")
    out={
      "schema":"befunge-stage1-four-cell-native-32-valid-fork-v2",
      "status":"NATIVE_QA_ONLY_FORK_CAUSALITY_PROFILE_STAGE1_OPEN",
      "source_git_blob":PIN,
      "candidate_git_blob":CANDIDATE_PIN,
      "exact_four_source_edits":[list(z) for z in candidate.PATCHES],
      "native_programs":64,
      "native_reference_cases":32,
      "zero_operand_cases":len(zeros),"nonzero_operand_cases":len(ones),
      "zero_operand_causal":sum(row["changed_final_output_or_termination"]
                                for row in zeros),
      "nonzero_operand_causal":sum(row["changed_final_output_or_termination"]
                                   for row in ones),
      "all_native_controls_match_reference":True,
      "all_branch_first_vectors_opposite":True,
      "all_five_motion_rejoins_observed":True,
      "automatic_promotion":False,"stage1_complete":False,
      "records":report
    }
    with open(REPORT,"wb") as stream:
        stream.write(json.dumps(out,sort_keys=True,indent=2)+"\n")
    print("NATIVE_QA_FOUR_CELL_32_FORK_CAUSALITY_PROFILE_PASS",
          "zero_causal",out["zero_operand_causal"],"of",len(zeros),
          "nonzero_causal",out["nonzero_operand_causal"],"of",len(ones))
    print("LAST_COMPLETED_STAGE=0 GEOMETRIC_SPAGHETTI_QA_PASS=NO")
if __name__=="__main__":main()
