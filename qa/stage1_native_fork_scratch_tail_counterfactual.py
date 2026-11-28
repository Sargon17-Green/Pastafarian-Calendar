#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only Native Befunge-98 scratch-cell liveness at an observed IP rejoin.

The pinned independent Native producer supplies each real fork's first common
five-event motion. Replay BOTH branches without modification, then run each
again after changing only the PyFunge Funge-space cell (1490,1600) at the
first matching post-fork IP checkpoint. Arithmetic stays inside Befunge-98.
Do not infer universal deadness, full state equivalence, or Stage-1 completion.
"""
from __future__ import print_function
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork

SCRATCH=(1490,1600)
EVIDENCE="/fork/current_fork_native_route_differential.json"
OUT="/fork/native_fork_scratch_tail_counterfactual.json"

def require(ok, why):
    if not ok:
        raise AssertionError(why)

class StepLimit(Exception):
    pass

def execute(source,raw,original_class,forced,offset,motion,mutate):
    output=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=output)
    program=Program(Befunge98,platform=platform)
    program.load_code(source)
    program.create_ip()
    require(len(program.ips)==1,"replay must start with one real Native IP")
    old_step=program.execute_step
    ticks=[0]
    gates=[]
    event=[None]
    tail={"potential_native_g_reads_of_scratch":0,
          "potential_native_p_writes_of_scratch":0,
          "executions_at_scratch_coordinate":0}
    point=program.ips[0].position.__class__(SCRATCH)
    expected_class=1-original_class if forced else original_class

    def hook(self):
        ticks[0]+=1
        if ticks[0]>fork.BOUND:
            raise StepLimit("bounded Native scratch intervention")
        if self.ips:
            require(len(self.ips)==1,"unexpected extra Native IP")
            ip=self.ips[0]
            pos=tuple(int(n) for n in ip.position)
            cell=self.space.get(ip.position)
            if pos==fork.GATE:
                require(cell==ord("|") and len(ip.stack[0])>=1,
                        "Native fork opcode or operand absent")
                observed=int(bool(ip.stack[0][-1]))
                require(observed==original_class,
                        "Native natural fork class drifted")
                if forced:
                    ip.stack[0][-1]=0 if observed else 1
                gates.append(ticks[0])
            if gates and ticks[0]==gates[0]+1+offset:
                require(event[0] is None,"duplicate rejoin intervention")
                current_motion=(pos[0],pos[1],
                                int(ip.delta[0]),int(ip.delta[1]),
                                len(ip.stack[0]))
                require(list(current_motion)==motion,
                        "measured Native IP is not at pinned common rejoin")
                before=int(self.space.get(point))
                require(before==(12 if expected_class else 32),
                        "Native scratch memory is not in measured fork state")
                value=(32 if before==12 else 12) if mutate else before
                if mutate:
                    # Deliberate QA runtime intervention, not a source mutation.
                    self.space.put(point,value)
                    require(int(self.space.get(point))==value,
                            "real Native Funge-space intervention failed")
                event[0]={"tick":ticks[0],"motion":list(current_motion),
                          "scratch_before":before,
                          "scratch_after":int(self.space.get(point)),
                          "intervention_performed":bool(mutate)}
            if event[0] is not None:
                if pos==SCRATCH:
                    tail["executions_at_scratch_coordinate"]+=1
                # This observes executable g/p candidates, not all possible
                # memory-read mechanisms or interpreter fingerprint semantics.
                if cell in (ord("g"),ord("p")) and not ip.stringmode:
                    contents=ip.stack[0]
                    n=2 if cell==ord("g") else 3
                    vals=[int(v) for v in list(contents)[-n:]]
                    while len(vals)<n:
                        vals.insert(0,0)
                    ox,oy=int(ip.offset[0]),int(ip.offset[1])
                    target=(vals[-2]+ox,vals[-1]+oy)
                    if target==SCRATCH:
                        name=("potential_native_g_reads_of_scratch" if cell==ord("g")
                              else "potential_native_p_writes_of_scratch")
                        tail[name]+=1
        return old_step()

    program.execute_step=hook.__get__(program,program.__class__)
    status="normal"
    try:
        program.execute()
    except StepLimit:
        status="step-limit"
    finally:
        del program.execute_step
    require(event[0] is not None and len(gates)>=1,
            "Native rejoin checkpoint was not actually reached")
    return {"status":status,"steps":ticks[0],
            "remaining_ips":len(program.ips),
            "output":output.getvalue().split(),
            "event":event[0],"post_checkpoint":tail}

def signature(data):
    return (data["status"],data["remaining_ips"],data["output"])

def main():
    require(os.path.isdir("/fork"),"Native evidence destination is missing")
    source=open(fork.SOURCE,"rb").read()
    require(fork.blob(source)==fork.PIN,"QA production source blob changed")
    with open(EVIDENCE,"rb") as stream:
        previous=json.load(stream)
    require(previous.get("source_git_blob")==fork.PIN and
            previous.get("valid_input_cases")==32 and
            len(previous.get("records",[]))==32,
            "Native rejoin provenance is not the pinned 32-case corpus")
    names={z[0]:(z[1],z[2]) for z in fork.native.CASES}
    names.update({z[0]:(z[1],z[2]) for z in fork.wide.CASES})
    results=[]
    for record in previous["records"]:
        label=record["case"]
        require(label in names and names[label][1],
                "scratch trial received invalid or unknown input")
        raw=" ".join(map(str,names[label][0]))+"\n"
        reference=fork.native.expected_for(*names[label][0])
        gate_class=record["gate_observed_nonzero"]
        step_zero=record["first_common_five_event_motion"]["real_motion_sample"][0]
        row={"case":label,"gate_observed_nonzero":gate_class,
             "branches":[]}
        for forced in (False,True):
            branch="forced-opposite" if forced else "natural"
            offset=record["first_common_five_event_motion"][
                "mutant_offset" if forced else "original_offset"]
            baseline=execute(source,raw,gate_class,forced,offset,step_zero,False)
            modified=execute(source,raw,gate_class,forced,offset,step_zero,True)
            assert_original=(record["mutant_step_count"] if forced
                             else record["control_step_count"])
            assert_status=(record["mutant_status"] if forced
                           else record["control_status"])
            require(baseline["steps"]==assert_original and
                    baseline["status"]==assert_status and
                    baseline["event"]["scratch_before"]==
                    modified["event"]["scratch_before"] and
                    baseline["event"]["scratch_after"]==
                    baseline["event"]["scratch_before"] and
                    modified["event"]["scratch_after"]!=
                    modified["event"]["scratch_before"],
                    "Native replay/source or intervention drifted: "+label+
                    "/"+branch)
            if not forced:
                require(baseline["status"]=="normal" and
                        baseline["remaining_ips"]==0 and
                        baseline["output"]==reference,
                        "unmodified Native replay differs from independent oracle")
            else:
                original_changed=(baseline["status"]!="normal" or
                                  baseline["remaining_ips"]!=0 or
                                  baseline["output"]!=reference)
                require(original_changed==record["changed_final_semantics"],
                        "real forced-fork output no longer matches earlier evidence")
            branch_record={"branch":branch,
                           "expected_executed_gate_nonzero":
                               1-gate_class if forced else gate_class,
                           "rejoin_offset":offset,
                           "native_control":baseline,
                           "native_scratch_flipped":modified,
                           "post_rejoin_semantics_changed":
                               signature(baseline)!=signature(modified),
                           "post_rejoin_step_count_changed":
                               baseline["steps"]!=modified["steps"]}
            row["branches"].append(branch_record)
            print("NATIVE_FORK_POST_REJOIN_SCRATCH_INTERVENTION_MEASURED",
                  label,branch,"cell_before",
                  baseline["event"]["scratch_before"],"cell_after",
                  modified["event"]["scratch_after"],"final_changed",
                  branch_record["post_rejoin_semantics_changed"],
                  "later_g_candidates",
                  modified["post_checkpoint"]["potential_native_g_reads_of_scratch"])
            sys.stdout.flush()
        results.append(row)
    require(len(results)==32 and
            all(len(row["branches"])==2 for row in results),
            "Native scratch tail corpus incomplete")
    report={"schema":"befunge-stage1-native-scratch-tail-v1",
            "status":"QA_ONLY_SCRATCH_LIVENESS_BOUNDED",
            "source_git_blob":fork.PIN,
            "native_real_program_executions":128,
            "valid_input_cases":32,
            "branch_pairs":64,
            "single_cell_mutant_executions":64,
            "scratch_coordinate":list(SCRATCH),
            "full_execution_state_equivalence_proven":False,
            "observed_semantic_change_pairs":sum(
                item["post_rejoin_semantics_changed"]
                for row in results for item in row["branches"]),
            "records":results}
    with open(OUT,"wb") as stream:
        stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_FORK_POST_REJOIN_SCRATCH_BOUNDED_CAUSALITY_PROFILE_PASS",
          "cases",len(results),"pairs",64,
          "changed",report["observed_semantic_change_pairs"])
    print("STAGE1_SEMANTIC_STATE_OWNERSHIP_FINAL_ACCEPTANCE=OPEN")

if __name__=="__main__":
    main()
