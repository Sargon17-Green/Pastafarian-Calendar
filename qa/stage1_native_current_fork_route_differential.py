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

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
GATE=(951,1335)
CASE_NAMES=tuple(row[0] for row in native.CASES if row[2])
INERT=frozenset(("zero_equal","forward_short"))
BOUND=160000
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
        return old_step()
    p.execute_step=hook.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except NativeBudgetExceeded:status="step-limit"
    finally:del p.execute_step
    return {"status":status,"output":out.getvalue().split(),
            "remaining_ips":len(p.ips),"steps":total[0],
            "gates":gate_events,"route":post}

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
                "real positive native fork replay invalid "+label)
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
                "first_common_five_event_motion":overlap}
        report.append(result)
        print("NATIVE_CURRENT_FORK_ROUTE_VS_OUTPUT_MEASURED",
              label,"real_route_changed",True,
              "final_output_causal",changed,
              "first_vector",first[:4],
              "forced_vector",opposite[:4],
              "common_5_event_motion",overlap is not None)
        sys.stdout.flush()
    require(len(report)==14 and sum(z["changed_final_semantics"] for z in report if z["case"] in ("zero_equal","foundation_cross","forward_short","mixed_small"))==2,
            "incomplete or unexpectedly classified Native fork corpus")
    data={"schema":"befunge-stage1-current-native-fork-route-differential-v1",
          "status":"QA_ONLY_UPSTREAM_FORK_CAUSALITY_OPEN",
          "source_git_blob":PIN,"real_PyFunge_runs":28,
          "valid_input_cases":14,
          "native_route_changed_cases":14,
          "final_semantics_changed_cases":sum(z["changed_final_semantics"] for z in report),
          "final_semantics_inert_cases":sum(not z["changed_final_semantics"] for z in report),
          "output_causality_not_universal":True,
          "records":report}
    with open(OUT,"wb") as sink:
        sink.write(json.dumps(data,sort_keys=True,indent=2)+"\n")
    print("NATIVE_CURRENT_UPSTREAM_FORK_ROUTE_VS_OUTPUT_CAUSALITY_PROFILE_PASS",
          "fourteen_real_branch_changes","mixed_output_causality")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO STAGE1_OPEN=YES")

if __name__=="__main__":
    main()
