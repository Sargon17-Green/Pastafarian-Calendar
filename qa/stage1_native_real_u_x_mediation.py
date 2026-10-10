#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real BF98 causal mediation: u TOSS transfer -> downstream x -> program.

Execute the ORIGINAL Befunge-98 code using native PyFunge, with two
independent, single-runtime-stack interventions: disrupt u slot0 1->0/-1
and optionally restore only the original x direction argument at the
actual executed x site 99 physical steps after u. The x opcode itself
must execute; source is never rewritten. Outputs are checked against
independent native Befunge reference. Test-only; not Stage1 acceptance.
"""
from __future__ import print_function
import hashlib,json,os,StringIO,sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as refs

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SRC="src/interleaved_work_counts.b98"
U=(954,1328);X=(950,1335)
CASES=("zero_equal","forward_short","recent_anchor_next")
OUT="/u-x-mediation"
BOUND=170000
def need(v,msg):
    if not v:raise AssertionError(msg)
class Budget(Exception):pass
def stack_view(ip):
    return [[str(int(v)) for v in frame] for frame in ip.stack]
def run(source,raw,delta,restore_x,control_x=None):
    output=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=output))
    p.load_code(source);p.create_ip()
    old=p.execute_step;num=[0];u_event=[None];x_event=[None]
    def step(self):
        num[0]+=1
        if num[0]>BOUND:raise Budget("Native u-x mediation counterfactual bound")
        need(len(self.ips)==1,"Native u-x source unexpectedly forked IP")
        ip=self.ips[0];at=tuple(map(int,ip.position))
        if at==U and u_event[0] is None:
            need(int(self.space.get(ip.position))==ord("u")
                 and not ip.stringmode
                 and stack_view(ip)==[["1","0","0"],["3"]],
                 "pinned original Native executed u and stacks drift")
            orig=stack_view(ip)
            if delta:ip.stack[0][0]=int(ip.stack[0][0])+delta
            altered=stack_view(ip)
            result=old()
            need(self.ips and self.ips[0] is ip,
                 "real executed u destroyed executing Native IP")
            u_event[0]={"tick":num[0],"position":list(U),
                        "delta":delta,"before":orig,
                        "executed":altered,"after":stack_view(ip)}
            return result
        if at==X and u_event[0] is not None and x_event[0] is None:
            need(int(self.space.get(ip.position))==ord("x")
                 and not ip.stringmode
                 and num[0]-u_event[0]["tick"]==99,
                 "Native downstream executed x not at pinned causal site")
            before=stack_view(ip)
            repaired=None
            if restore_x:
                need(control_x is not None and delta!=0,
                     "Native x rescue requires independent control x stack")
                want=control_x["pre_actual"]
                need(len(before)==len(want),
                     "Native x stack-stack layout differs pre-rescue")
                diffs=[]
                for j,(a,b) in enumerate(zip(before,want)):
                    need(len(a)==len(b),
                         "Native x stack-size mismatch before rescue")
                    for k,(va,vb) in enumerate(zip(a,b)):
                        if va!=vb:diffs.append((j,k,va,vb))
                need(len(diffs)==1,
                     "Expected exactly one u-mediated x argument difference")
                j,k,actual,expected=diffs[0]
                need(j==len(ip.stack)-1 and
                     k>=len(ip.stack[j])-2,
                     "Changed u value not x direction operand")
                ip.stack[j][k]=int(expected)
                repaired={"stack_index":j,"slot_index":k,
                          "mutant_value":actual,
                          "control_value":expected}
                need(stack_view(ip)==want,"Native restored x argument drift")
            effective=stack_view(ip)
            result=old()
            need(self.ips and self.ips[0] is ip,
                 "Native x unexpectedly stopped executing IP")
            x_event[0]={"tick":num[0],"position":list(X),
                        "opcode":"x","pre_actual":before,
                        "pre_executed":effective,
                        "post":stack_view(ip),
                        "post_position":list(map(int,ip.position)),
                        "post_delta":list(map(int,ip.delta)),
                        "restoration":repaired}
            return result
        return old()
    p.execute_step=step.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except Budget:status="step-limit"
    finally:del p.execute_step
    need(u_event[0] is not None and x_event[0] is not None,
         "Native u and downstream physical x causal witnesses absent")
    return {"status":status,"steps":num[0],"remaining_ips":len(p.ips),
            "output":output.getvalue().split(),
            "u":u_event[0],"x":x_event[0]}

def main():
    need(os.path.isdir(OUT),"Native u-x evidence volume missing")
    source=open(SRC,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()==PIN,
         "original native arithmetic source SHA drift")
    cases=dict((a,(f,v)) for a,f,v in refs.CASES)
    records=[]
    for label in CASES:
        fields,valid=cases[label]
        need(valid,"u-x mediation requires valid signed-day input")
        raw=" ".join(map(str,fields))+"\n"
        expected=refs.expected_for(*fields)
        need(len(expected)==7 and expected!=["-1"]*7,
             "independent Befunge reference failed")
        control=run(source,raw,0,False)
        need(control["status"]=="normal" and control["remaining_ips"]==0
             and control["output"]==expected
             and control["x"]["post_delta"]==[-1,0],
             "Native BF98 original reference/x vector mismatch")
        pairs=[]
        for delta in (-1,-2):
            interrupted=run(source,raw,delta,False)
            restored=run(source,raw,delta,True,control["x"])
            need(interrupted["u"]["tick"]==control["u"]["tick"]
                 and restored["u"]["tick"]==control["u"]["tick"]
                 and interrupted["x"]["tick"]==control["x"]["tick"]
                 and restored["x"]["tick"]==control["x"]["tick"],
                 "Native u and x timing differs before causal intervention")
            need(interrupted["x"]["post_delta"]==[-1+delta,0]
                 and restored["x"]["post_delta"]==[-1,0],
                 "actual executed x vector was not rescued")
            need(interrupted["status"]=="step-limit"
                 and interrupted["steps"]==BOUND+1,
                 "Native unrescued mutant did not reproduce bounded divergence")
            need(restored["status"]=="normal"
                 and restored["remaining_ips"]==0
                 and restored["output"]==expected,
                 "actual Native BF98 x operand restoration did not rescue oracle")
            pairs.append({"u_delta":delta,"mutant":interrupted,
                          "rescue":restored,
                          "restored_same_reference_7":True,
                          "rescue_only_one_x_operand":True})
            print("NATIVE_REAL_U_X_MEDIATION_RESCUE_PASS",label,"delta",delta,
                  "native_mutant_steps",interrupted["steps"],
                  "rescued_steps",restored["steps"])
            sys.stdout.flush()
        records.append({"case":label,"reference_7":expected,
                        "control":control,"pairs":pairs})
    report={"schema":"befunge-stage1-real-u-to-x-native-mediation-v1",
            "scope":"THREE_VALID_NATIVE_INPUTS_X_OPERAND_RESCUE_UNMODIFIED_BF98",
            "source_git_blob":PIN,"native_executions":15,
            "independent_native_references":3,
            "last_completed_stage":0,"stage1_complete":False,
            "geometric_spaghetti_qa_pass":False,
            "production_modified":False,"records":records}
    with open(OUT+"/native_real_u_x_mediation.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_REAL_BF98_U_X_MEDIATION_15_RUNS_SIX_RESCUES_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
