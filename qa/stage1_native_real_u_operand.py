#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98 executed-u operand causality: real stack-stack transfer.

At the first executed u (954,1328), change only the integer argument on
the active TOSS by +1/-1 while leaving the actual native u executable.
Capture real pre/post Funge-98 full stack-of-stacks, vectors and outputs.
Befunge source and independent native Befunge reference are unchanged.
"""
from __future__ import print_function
import hashlib,json,os,StringIO,sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as reference

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
TARGET=(954,1328)
OUT="/u-operand"
CASES=("zero_equal","forward_short","recent_anchor_next")
DELTAS=(0,1,-1)
BOUND=200000
def need(ok,m):
    if not ok:raise AssertionError(m)
class StepLimit(Exception):pass
def frames(ip):
    return [[str(int(v)) for v in layer] for layer in ip.stack]
def context(ip):
    return {"position":[int(v) for v in ip.position],
            "direction":[int(v) for v in ip.delta],
            "offset":[int(v) for v in ip.offset],
            "string_mode":bool(ip.stringmode),
            "frames":frames(ip)}
def execute(source,raw,delta):
    output=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=output))
    p.load_code(source);p.create_ip()
    old=p.execute_step;step=[0];event=[None];tail=[]
    def hook(self):
        step[0]+=1
        if step[0]>BOUND:raise StepLimit("bounded real BF98 u-operand probe")
        need(len(self.ips)==1,"unexpected Native multi-IP execution")
        ip=self.ips[0]
        pos=tuple(int(v) for v in ip.position)
        if pos==TARGET and event[0] is None:
            need(int(self.space.get(ip.position))==ord("u") and
                 not ip.stringmode and len(ip.stack)==2 and
                 len(ip.stack[0])>=1,
                 "real BF98 stack-stack transfer site invalid")
            before=context(ip)
            operand=int(ip.stack[0][-1])
            if delta:ip.stack[0][-1]=operand+delta
            execution_before=context(ip)
            result=old()
            need(len(self.ips)==1 and self.ips[0] is ip,
                 "u unexpectedly quit or forked")
            after=context(ip)
            event[0]={"tick":step[0],"coordinate":list(TARGET),
                      "executed_opcode":"u","operand_original":operand,
                      "operand_executed":operand+delta,"operand_delta":delta,
                      "pre_original":before,"pre_executed":execution_before,
                      "post":after}
            return result
        if event[0] is not None and len(tail)<128:
            tail.append([pos[0],pos[1],
                         int(ip.delta[0]),int(ip.delta[1])])
        return old()
    p.execute_step=hook.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except StepLimit:status="step-limit"
    finally:del p.execute_step
    need(event[0] is not None and len(tail)==128,
         "Native u witness or 128 subsequent real IP steps missing")
    return {"status":status,"steps":step[0],"ips":len(p.ips),
            "output":output.getvalue().split(),
            "u_event":event[0],"post_u_128_real_motion":tail}

def main():
    need(os.path.isdir(OUT),"Native u QA evidence volume unavailable")
    source=open(SOURCE,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()==PIN,
         "pinned Befunge QA production source changed")
    book=dict((n,(fields,valid)) for n,fields,valid in reference.CASES)
    rows=[]
    for name in CASES:
        fields,valid=book[name]
        need(valid,"Native u test must use valid source input")
        raw=" ".join(map(str,fields))+"\n"
        expected=reference.expected_for(*fields)
        need(len(expected)==7,"native independent reference returned wrong shape")
        control=execute(source,raw,0)
        need(control["status"]=="normal" and control["ips"]==0 and
             control["output"]==expected,
             "real Native untouched u path did not match BF98 reference")
        others=[]
        for change in (1,-1):
            trial=execute(source,raw,change)
            need(trial["u_event"]["tick"]==control["u_event"]["tick"] and
                 trial["u_event"]["pre_original"]==control["u_event"]["pre_original"]
                 and trial["u_event"]["pre_executed"]!=control["u_event"]["pre_executed"]
                 and trial["u_event"]["executed_opcode"]=="u",
                 "only selected live Native u TOSS operand must differ")
            effect=(trial["status"]!="normal" or trial["ips"]!=0
                    or trial["output"]!=expected)
            others.append({"delta":change,"run":trial,
                           "output_or_termination_effect":effect,
                           "immediate_post_state_differs":
                             trial["u_event"]["post"]!=control["u_event"]["post"],
                           "first_128_directed_route_differs":
                             trial["post_u_128_real_motion"]!=
                             control["post_u_128_real_motion"]})
            print("NATIVE_U_STACK_TRANSFER_CAUSAL_MEASURED",
                  name,"delta",change,"operand",
                  trial["u_event"]["operand_original"],"to",
                  trial["u_event"]["operand_executed"],
                  "stack_changed",
                  others[-1]["immediate_post_state_differs"],
                  "final_effect",effect,"status",trial["status"])
            sys.stdout.flush()
        rows.append({"case":name,"reference_7":expected,
                     "control":control,"mutants":others})
    report={"schema":"befunge-stage1-native-real-u-operand-transfer-v1",
            "scope":"THREE_VALID_NATIVE_INPUTS_ONE_ACTUAL_U_SITE_PLUS_MINUS_ONE",
            "source_git_blob":PIN,"actual_native_programs":9,
            "independent_native_references":3,"last_completed_stage":0,
            "stage1_complete":False,"production_modified":False,
            "full_geometric_acceptance":False,
            "cases":list(CASES),"records":rows}
    with open(OUT+"/u_operand_native_witness.json","wb") as f:
        f.write(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_REAL_U_OPERAND_9_PROGRAMS_6_MUTATIONS_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
