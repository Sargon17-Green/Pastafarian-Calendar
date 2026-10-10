#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Stage-1 QA: modify one Funge-space cell immediately before real g.
All arithmetic and read-site semantics remain genuine pinned Befunge-98.
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
import stage1_native_current_fork_route_differential as prior
import stage1_native_concurrent_pg_fault_isolation as geometry

OUT="/fork/native_pre_g_scratch_intervention.json"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"

def need(condition,reason):
    if not condition:raise AssertionError(reason)

class Limit(Exception):pass

def trial(raw,alter):
    output=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=output))
    p.load_code(geometry.CODE)
    p.create_ip()
    point=p.ips[0].position.__class__(geometry.CELL)
    need(p.space.get(point)==32,"Native scratch must start implicit blank")
    old_step=p.execute_step
    count=[0]
    seen={"gate":0,"p":0,"g":0}
    observed=[None]
    def hook(self):
        count[0]+=1
        if count[0]>prior.BOUND:raise Limit("Native read-site limit")
        if self.ips:
            need(len(self.ips)==1,"unanticipated multiple Native IPs")
            ip=self.ips[0]
            pos=tuple(ip.position)
            cell=self.space.get(ip.position)
            if pos==prior.GATE:
                need(cell==ord("|") and ip.stack[0] and
                     bool(ip.stack[0][-1]),
                     "pre-g test did not take original nonzero Native fork")
                seen["gate"]+=1
            if pos==geometry.P:
                need(cell==ord("p") and self.space.get(point)==32,
                     "Native p visited with dirty scratch cell")
                seen["p"]+=1
            if pos==geometry.G:
                need(cell==ord("g") and seen["g"]==0 and
                     len(ip.stack[0])>=2 and
                     tuple(map(int,list(ip.stack[0])[-2:]))==geometry.CELL and
                     seen["gate"]==seen["p"]==1 and
                     int(self.space.get(point))==12,
                     "Native g did not follow pinned p write")
                seen["g"]+=1
                if alter:
                    self.space.put(point,32)
                before=int(self.space.get(point))
                need(before==(32 if alter else 12),
                     "runtime Native g-cell modification failed")
                result=old_step()
                need(self.ips and self.ips[0] is ip and ip.stack[0] and
                     int(ip.stack[0][-1])==before,
                     "real Native g failed to return modified Funge-space value")
                observed[0]={"step":count[0],"before_read":before,
                             "g_returned":int(ip.stack[0][-1]),
                             "intervened":bool(alter),
                             "coordinate":list(geometry.CELL)}
                return result
        return old_step()
    p.execute_step=hook.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except Limit:status="step-limit"
    finally:del p.execute_step
    need(seen=={"gate":1,"p":1,"g":1} and observed[0] is not None,
         "Native p/g was not executed exactly once")
    return {"status":status,"steps":count[0],"remaining_ips":len(p.ips),
            "output":output.getvalue().split(),"real_g":observed[0]}

def signature(data):
    return data["status"],data["remaining_ips"],data["output"]

def main():
    need(os.path.isdir("/fork"),"CI evidence directory missing")
    src=geometry.CODE
    need(prior.blob(src)==PIN,"active Native source blob not pinned")
    with open("/fork/current_fork_native_route_differential.json","rb") as f:
        baseline=json.load(f)
    need(baseline.get("source_git_blob")==PIN and
         len(baseline.get("records",[]))==32,
         "the pinned Native fork corpus is missing")
    cases={item[0]:(item[1],item[2]) for item in prior.native.CASES}
    cases.update({item[0]:(item[1],item[2]) for item in prior.wide.CASES})
    data=[]
    for old in baseline["records"]:
        if old["gate_observed_nonzero"]!=1:continue
        label=old["case"]
        need(label in cases and cases[label][1],
             "Native pre-g test must receive valid recorded case")
        fields=cases[label][0]
        raw=" ".join(map(str,fields))+"\n"
        want=prior.native.expected_for(*fields)
        a=trial(raw,False)
        b=trial(raw,True)
        need(a["status"]=="normal" and a["remaining_ips"]==0 and
             a["output"]==want and a["steps"]==old["control_step_count"] and
             a["real_g"]["g_returned"]==12 and
             b["real_g"]["g_returned"]==32 and
             a["real_g"]["step"]==b["real_g"]["step"],
             "Native pre-g baseline reference or read-site witness drift: "+label)
        changed=signature(a)!=signature(b)
        data.append({"case":label,"control":a,"mutant":b,
                     "final_semantics_changed":changed,
                     "step_count_changed":a["steps"]!=b["steps"]})
        print("NATIVE_PRE_G_ACTUAL_READ_CONTRAST",label,
              "actual_control_read",12,"actual_mutant_read",32,
              "final_changed",changed)
        sys.stdout.flush()
    need(len(data)==20,"native nonzero-fork sample must contain 20 cases")
    report={"schema":"befunge-stage1-pre-g-native-scratch-v1",
            "status":"QA_ONLY_EARLY_READ_CAUSALITY",
            "source_git_blob":PIN,
            "scratch_coordinate":list(geometry.CELL),
            "valid_inputs":20,"real_native_executions":40,
            "g_return_value_changed_pairs":20,
            "final_semantic_changed_pairs":sum(r["final_semantics_changed"]
                                                for r in data),
            "stage1_final_acceptance":False,"records":data}
    with open(OUT,"wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_PRE_G_ACTUAL_READ_20_PAIR_INTERVENTION_PASS",
          "final_changed",report["final_semantic_changed_pairs"])
    print("CURRENT_STAGE=1 LAST_COMPLETED_STAGE=0")

if __name__=="__main__":
    main()
