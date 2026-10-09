#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native current-source | fault differential: measured route vs result.

The prior report records that forced opposite | is output-inert for two
valid inputs. This is an independent diagnostic: real PyFunge execution
must demonstrate the two *different instruction vectors/routes* and
separately classify whether the complete seven-field Native result changed.

Only the operand immediately before the executed native | is optionally
flipped. No Funge source cells are edited; no arithmetic is reimplemented
in Python. This diagnosis does not close any global Stage-1 acceptance.
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
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
GATE=(951,1335)
CASE_NAMES=tuple(row[0] for row in native.CASES if row[2])+tuple(row[0] for row in wide.CASES if row[2])
INERT=frozenset(("zero_equal","forward_short"))
BOUND=750000
WINDOW=512
OUT="/fork/current_fork_native_route_differential.json"

def require(condition,why):
    if not condition: raise AssertionError(why)

class NativeBudgetExceeded(Exception):pass

def blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def native_run(source,raw,opposite):
    out=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=out)
    p=Program(Befunge98,platform=platform)
    p.load_code(source)
    p.create_ip()
    require(len(p.ips)==1,"Native | diagnostic must start with one IP")
    old_step=p.execute_step
    total=[0]
    gate_events=[]
    post=[]
    post_toss=[]
    def hook(self):
        total[0]+=1
        if total[0]>BOUND:
            raise NativeBudgetExceeded("bounded Native route experiment")
        if self.ips:
            require(len(self.ips)==1,
                    "the observed native fork became concurrent unexpectedly")
            ip=self.ips[0]
            xy=tuple(ip.position)
            if xy==GATE:
                require(self.space.get(ip.position)==ord("|"),
                        "Native executable fork opcode at pinned cell changed")
                stack=ip.stack[0]
                require(len(stack)>0,"Native | invoked without operand")
                prev=int(bool(stack[-1]))
                if opposite:
                    stack[-1]=0 if prev else 1
                gate_events.append({"step":total[0],"original":prev,
                                    "executed":int(bool(stack[-1])),
                                    "depth":len(stack)})
            elif gate_events and len(post)<WINDOW:
                post.append((int(ip.position[0]),int(ip.position[1]),
                             int(ip.delta[0]),int(ip.delta[1]),
                             len(ip.stack[0])))
                # Capture actual Native TOSS at every observed post-| IP step.
                # This is stronger than motion-only reconvergence, but does
                # not claim equivalence of SOSS, Funge-space or full state.
                post_toss.append(tuple(str(v) for v in ip.stack[0]))
        return old_step()
    p.execute_step=hook.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except NativeBudgetExceeded:status="step-limit"
    finally:del p.execute_step
    return {"status":status,"output":out.getvalue().split(),
            "remaining_ips":len(p.ips),"steps":total[0],
            "gates":gate_events,"route":post,
            "post_toss":post_toss}

def common_subpath(a,b,length):
    # A common 5-event native directed motion window is stronger than a
    # single coincident grid cell. This is merely *observed*, never assumed.
    indices={}
    for i in range(len(a)-length+1):
        key=tuple(a[i:i+length])
        indices.setdefault(key,i)
    for j in range(len(b)-length+1):
        key=tuple(b[j:j+length])
        if key in indices:
            return {"original_offset":indices[key],"mutant_offset":j,
                    "real_motion_sample":list(key)}
    return None

def main():
    require(os.path.isdir("/fork"),"Native route evidence destination missing")
    src=open(SOURCE,"rb").read()
    require(blob(src)==PIN,"current-source | diff must match exact QA Git blob")
    labels={z[0]:(z[1],z[2]) for z in native.CASES}
    labels.update({z[0]:(z[1],z[2]) for z in wide.CASES})
    report=[]
    for label in CASE_NAMES:
        fields,valid=labels[label]
        require(valid,"native fork diagnosis must use valid input")
        raw=" ".join(map(str,fields))+"\n"
        expected=native.expected_for(*fields)
        unmodified=native_run(src,raw,False)
        altered=native_run(src,raw,True)
        require(unmodified["status"]=="normal" and
                unmodified["remaining_ips"]==0 and
                unmodified["output"]==expected and
                len(unmodified["gates"])==1,
                "real positive native fork replay invalid "+label+" status="+str(unmodified["status"])+" steps="+str(unmodified["steps"])+" observed="+repr(unmodified["output"])+" reference="+repr(expected))
        a=unmodified["gates"][0];b=altered["gates"][0]
        require(a["original"]==a["executed"] and
                a["original"]==b["original"] and
                b["executed"]==1-a["executed"] and
                a["depth"]==b["depth"] and len(altered["gates"])>=1,
                "fork operand counterfactual did not flip precisely one Native class "+label)
        first=unmodified["route"][0]
        opposite=altered["route"][0]
        require(first[:4]!=opposite[:4] and
                first[2]==opposite[2]==0 and
                first[3]==-opposite[3] and
                first[3]!=0,
                "Native fork operand changed but IP did not choose opposite directions "+label)
        changed=(altered["status"]!="normal" or
                 altered["remaining_ips"]!=0 or
                 altered["output"]!=expected)
        if label in INERT:
            require(not changed,
                    "frozen formerly inert Native fork became output-causal "+label)
        elif label in ("foundation_cross","mixed_small"):
            require(changed,
                    "frozen formerly causal Native fork became output-inert "+label)
        overlap=common_subpath(unmodified["route"],altered["route"],5)
        require(overlap is not None,"missing real Native five-motion rejoin "+label)
        require(len(unmodified["post_toss"])==len(unmodified["route"]) and
                len(altered["post_toss"])==len(altered["route"]),
                "Native route/TOSS snapshot counts do not align "+label)
        ia=overlap["original_offset"]
        ib=overlap["mutant_offset"]
        stack_a=unmodified["post_toss"][ia:ia+5]
        stack_b=altered["post_toss"][ib:ib+5]
        require(len(stack_a)==len(stack_b)==5,
                "incomplete real Native five-step TOSS rejoin "+label)
        equal_toss=[a==b for a,b in zip(stack_a,stack_b)]
        # Negative control: a forged TOSS snapshot with unchanged native
        # IP motion must not pass the exact stack comparison.
        tampered=list(stack_a)
        tampered[0]=tampered[0]+("__forged_toss__",)
        require(not all(a==b for a,b in zip(stack_a,tampered)),
                "rejoin TOSS audit accepted deliberately forged stack content")
        result={"case":label,"gate_observed_nonzero":a["executed"],
                "gate_forced_nonzero":b["executed"],
                "native_first_control_vector":first,
                "native_first_mutant_vector":opposite,
                "different_native_route":True,
                "changed_final_semantics":changed,
                "control_status":unmodified["status"],
                "mutant_status":altered["status"],
                "mutant_output_equal_to_oracle":altered["output"]==expected,
                "control_step_count":unmodified["steps"],
                "mutant_step_count":altered["steps"],
                "captured_native_route_steps":len(unmodified["route"]),
                "captured_counterfactual_route_steps":len(altered["route"]),
                "first_common_five_event_motion":overlap,
                "first_rejoin_native_toss_equal_each_step":equal_toss,
                "first_rejoin_native_toss_equal_count":sum(equal_toss),
                "first_rejoin_native_toss_identical_all_five":all(equal_toss),
                "first_rejoin_toss_depth_control":[len(s) for s in stack_a],
                "first_rejoin_toss_depth_forced":[len(s) for s in stack_b],
                "first_rejoin_toss_sha256_control":[hashlib.sha256(repr(s)).hexdigest() for s in stack_a],
                "first_rejoin_toss_sha256_forced":[hashlib.sha256(repr(s)).hexdigest() for s in stack_b],
                "full_semantic_state_equivalence_proven":False}
        report.append(result)
        print("NATIVE_CURRENT_FORK_ROUTE_VS_OUTPUT_MEASURED",
              label,"real_route_changed",True,
              "final_output_causal",changed,
              "first_vector",first[:4],
              "forced_vector",opposite[:4],
              "common_5_event_motion",overlap is not None,
              "rejoin_toss_equal_steps",sum(equal_toss))
        sys.stdout.flush()
    require(len(report)==32 and sum(z["changed_final_semantics"] for z in report if z["case"] in ("zero_equal","foundation_cross","forward_short","mixed_small"))==2,
            "incomplete or unexpectedly classified Native fork corpus")
    zeros=[z for z in report if z["gate_observed_nonzero"]==0]
    ones=[z for z in report if z["gate_observed_nonzero"]==1]
    # Befunge-98 | sends zero downward (+y) and nonzero upward (-y).
    # Native evidence: all 12 zero-operand cases are output-causal,
    # while all 20 nonzero-operand cases are output-inert under inversion.
    require(len(zeros)==12 and len(ones)==20 and
            all(z["changed_final_semantics"] for z in zeros) and
            all(not z["changed_final_semantics"] for z in ones),
            "32-case Native fork route/output dependence classification drifted")
    require(all(z["first_common_five_event_motion"] is not None for z in report),
            "expected 32 actual Native five-motion reconvergences missing")
    data={"schema":"befunge-stage1-current-native-fork-route-differential-v3",
          "status":"QA_ONLY_UPSTREAM_FORK_CAUSALITY_OPEN",
          "source_git_blob":PIN,"real_PyFunge_runs":64,
          "valid_input_cases":32,
          "native_route_changed_cases":32,
          "final_semantics_changed_cases":sum(z["changed_final_semantics"] for z in report),
          "final_semantics_inert_cases":sum(not z["changed_final_semantics"] for z in report),
          "output_causality_not_universal":True,
          "zero_operand_cases":len(zeros),
          "zero_operand_final_causal_cases":sum(z["changed_final_semantics"] for z in zeros),
          "nonzero_operand_cases":len(ones),
          "nonzero_operand_final_inert_cases":sum(not z["changed_final_semantics"] for z in ones),
          "native_toss_rejoin_snapshots_measured":len(report)*5*2,
          "native_toss_tamper_negative_controls":len(report),
          "native_toss_equal_all_five_cases":sum(z["first_rejoin_native_toss_identical_all_five"] for z in report),
          "full_fungespace_or_soss_equivalence_not_claimed":True,
          "records":report}
    with open(OUT,"wb") as sink:
        sink.write(json.dumps(data,sort_keys=True,indent=2)+"\n")
    print("NATIVE_CURRENT_UPSTREAM_FORK_ROUTE_VS_OUTPUT_CAUSALITY_PROFILE_PASS",
          "thirty_two_real_branch_changes","mixed_output_causality")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO STAGE1_OPEN=YES")

if __name__=="__main__":
    main()
