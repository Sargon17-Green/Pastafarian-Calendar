#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1 QA: complete post-fork Native BF98 IP evidence in four input pairs.

Every post-| instruction to halt is witnessed in both arms. Oracle values
are produced by independent Native Befunge reference. Test-only candidate
only; no change to production, canonical branch, or Stage 2.
"""
from __future__ import print_function
import json,os,sys
from funge.program import Program
import stage1_native_current_fork_route_differential as fork
import stage1_native_diverse_geometry as suite
import stage1_native_reflective_candidate_domain_matrix as wide
import stage1_native_lower_feedback_semantic_candidate as candidate

OUT="/full-postfork"
CASES=("zero_equal","foundation_cross","forward_short","mixed_small")
SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
def need(v,msg):
    if not v:raise AssertionError(msg)

def run_full(source,raw,opposite):
    trace=[]
    step=[0]
    post=[False]
    gates=[0]
    original_step=Program.execute_step
    def observer(self):
        step[0]+=1
        need(step[0]<=fork.BOUND,"native full post-fork timeout")
        need(len(self.ips)==1,"native full witness expects one IP")
        ip=self.ips[0]
        xy=(int(ip.position[0]),int(ip.position[1]))
        gate=(xy==fork.GATE)
        if post[0]:
            trace.append([step[0],xy[0],xy[1],
                          int(ip.delta[0]),int(ip.delta[1]),
                          int(self.space.get(ip.position)),
                          int(bool(ip.stringmode))])
        result=original_step(self)
        if gate:
            gates[0]+=1
            post[0]=True
        return result
    Program.execute_step=observer
    try:
        measured=fork.native_run(source,raw,opposite)
    finally:
        Program.execute_step=original_step
    need(gates[0]==1 and len(measured["gates"])==1,
         "exactly one actual native conditional fork required")
    tick=measured["gates"][0]["step"]
    need(step[0]==measured["steps"]
         and len(trace)==measured["steps"]-tick
         and len(trace)>512 and trace[0][0]==tick+1
         and trace[-1][0]==measured["steps"],
         "post-fork native trace not complete through halt")
    need([e[1:5] for e in trace[:512]]==
         [list(e[:4]) for e in measured["route"]],
         "full observer contradicts 512-step independent Native witness")
    return {
       "status":measured["status"],
       "steps":measured["steps"],
       "remaining_ips":measured["remaining_ips"],
       "output":measured["output"],
       "gate":measured["gates"][0],
       "total_p_writes":measured["observed_native_p_writes"],
       "total_g_reads":len(measured["native_g_reads_raw"]),
       "native_p_history":measured["native_p_writes_raw"],
       "native_g_history":measured["native_g_reads_raw"],
       "first_512_motion":[list(e[:4]) for e in measured["route"]],
       "complete_postfork_trace":trace,
       "final_scratch_value":measured["final_scratch_value"]
    }

def main():
    need(os.path.isdir(OUT),"Native witness output mount missing")
    original=open(SOURCE,"rb").read()
    need(candidate.git_blob(original)==PIN,"original QA native source changed")
    altered=candidate.candidate_bytes(original)
    need(candidate.git_blob(altered)==CANDIDATE,
         "candidate differs from pinned exact four physical cell edits")
    with open(OUT+"/four_cell_candidate.b98","wb") as target:
        target.write(altered)
    inputs=dict((n,(fields,valid))
                for n,fields,valid in list(suite.CASES)+list(wide.CASES))
    records=[]
    for label in CASES:
        fields,valid=inputs[label]
        need(valid,"full-postfork witness requires valid Native input")
        raw=" ".join(map(str,fields))+"\n"
        expected=suite.expected_for(*fields)
        a=run_full(altered,raw,False)
        b=run_full(altered,raw,True)
        ga=a["gate"];gb=b["gate"]
        need(a["status"]==b["status"]=="normal" and
             a["remaining_ips"]==b["remaining_ips"]==0
             and a["output"]==expected
             and ga["step"]==gb["step"]
             and ga["original"]==ga["executed"]==gb["original"]
             and gb["executed"]==1-ga["executed"],
             "independent BF98 output or actual opposite gate drift: "+label)
        records.append({"label":label,"fields":[str(v) for v in fields],
                        "reference_7":expected,"control":a,"forced":b,
                        "changed_final_output":b["output"]!=expected})
        print("NATIVE_FULL_POSTFORK_PAIR_MEASURED",label,
              "native_control_instructions",len(a["complete_postfork_trace"]),
              "native_forced_instructions",len(b["complete_postfork_trace"]),
              "final_output_causal",b["output"]!=expected)
        sys.stdout.flush()
    report={
       "schema":"befunge-stage1-four-cell-native-full-postfork-trace-v1",
       "status":"QA_ONLY_COMPLETE_POSTFORK_FOUR_INPUT_PAIRS_STAGE1_OPEN",
       "source_git_blob":PIN,"candidate_git_blob":CANDIDATE,
       "selected_cases":list(CASES),"native_executions":8,
       "last_completed_stage":0,"stage1_complete":False,
       "full_functional_acceptance":False,"geometric_acceptance":False,
       "automatic_promotion":False,"records":records}
    with open(OUT+"/native_full_postfork_four_pairs.json","wb") as file:
        file.write(json.dumps(report,sort_keys=True,separators=(",",":"))+"\n")
    print("NATIVE_EIGHT_COMPLETE_POSTFORK_TRAJECTORIES_QA_ONLY_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
