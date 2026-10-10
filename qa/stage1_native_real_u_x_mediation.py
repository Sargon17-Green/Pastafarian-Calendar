#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real Native BF98 mediation: u -> two stack channels -> downstream x.

Test 3 distinct valid native inputs, 2 u first-slot counterfactuals, and
2 distinct x intervention modes: restore ONLY x direction argument or
restore BOTH observed changed pre-x stack values. All five variants use
the same original BF98 source; actual x executes under PyFunge. Outcome
is measured, not assumed. Independent BF98 native reference supplies
all seven numeric values. Never Stage1 automatic acceptance.
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
def run(source,raw,delta,mode):
    need(mode in ("none","direction","full"),"Native x rescue mode invalid")
    output=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=output))
    p.load_code(source);p.create_ip()
    old=p.execute_step;num=[0];u_event=[None];x_event=[None]
    def step(self):
        num[0]+=1
        if num[0]>BOUND:raise Budget("Native u-x mediation bounded")
        need(len(self.ips)==1,"Native u-x source unexpectedly forked IP")
        ip=self.ips[0];at=tuple(map(int,ip.position))
        if at==U and u_event[0] is None:
            need(int(self.space.get(ip.position))==ord("u")
                 and not ip.stringmode
                 and stack_view(ip)==[["1","0","0"],["3"]],
                 "pinned actual Native executed u or its input stacks drift")
            orig=stack_view(ip)
            if delta:ip.stack[0][0]=int(ip.stack[0][0])+delta
            altered=stack_view(ip)
            result=old()
            need(self.ips and self.ips[0] is ip,
                 "Native executed u destroyed current IP")
            u_event[0]={"tick":num[0],"position":list(U),
                        "delta":delta,"before":orig,
                        "executed":altered,"after":stack_view(ip)}
            return result
        if at==X and u_event[0] is not None and x_event[0] is None:
            need(int(self.space.get(ip.position))==ord("x")
                 and not ip.stringmode
                 and num[0]-u_event[0]["tick"]==99,
                 "real Native downstream x at expected physical event missing")
            before=stack_view(ip)
            expected=[["1",-1,0]] if False else [["1","-1","0"]]
            measured=[[str(1+delta),str(-1+delta),"0"]]
            need(before==measured,
                 "u->x Native two-channel physical stack differs from "
                 +repr(measured)+" observed "+repr(before))
            changes=[]
            if mode in ("direction","full"):
                need(delta!=0,"Native x intervention requires u mutant")
                ip.stack[0][1]=-1
                changes.append({"frame":0,"slot":1,
                                "from":str(-1+delta),"to":"-1"})
            if mode=="full":
                ip.stack[0][0]=1
                changes.append({"frame":0,"slot":0,
                                "from":str(1+delta),"to":"1"})
            effective=stack_view(ip)
            expected_effective=(
                measured if mode=="none"
                else [[str(1+delta),"-1","0"]] if mode=="direction"
                else [["1","-1","0"]])
            need(effective==expected_effective,
                 "Native BF98 x intervention changed unrequested stack cells")
            result=old()
            need(self.ips and self.ips[0] is ip,
                 "Native x unexpectedly stopped executing IP")
            observed=list(map(int,ip.delta))
            want=[-1+delta,0] if mode=="none" else [-1,0]
            need(observed==want,
                 "actual BF98 x did not follow mediated direction operands")
            x_event[0]={"tick":num[0],"position":list(X),
                        "opcode":"x","mode":mode,
                        "pre_actual":before,"pre_executed":effective,
                        "post":stack_view(ip),
                        "post_position":list(map(int,ip.position)),
                        "post_delta":observed,
                        "changes":changes}
            return result
        return old()
    p.execute_step=step.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except Budget:status="step-limit"
    finally:del p.execute_step
    need(u_event[0] is not None and x_event[0] is not None,
         "actual Native BF98 u and x source event not witnessed")
    return {"status":status,"steps":num[0],"remaining_ips":len(p.ips),
            "output":output.getvalue().split(),
            "u":u_event[0],"x":x_event[0]}

def succeeded(run,ref):
    return run["status"]=="normal" and run["remaining_ips"]==0 and run["output"]==ref
def main():
    need(os.path.isdir(OUT),"Native u-x evidence volume missing")
    source=open(SRC,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()==PIN,
         "original BF98 arithmetic source SHA drift")
    cases=dict((a,(f,v)) for a,f,v in refs.CASES)
    records=[]
    for label in CASES:
        fields,valid=cases[label]
        need(valid,"Native u/x mediator uses only valid signed-day input")
        raw=" ".join(map(str,fields))+"\n"
        expected=refs.expected_for(*fields)
        need(len(expected)==7 and expected!=["-1"]*7,
             "independent real BF98 reference failed")
        control=run(source,raw,0,"none")
        need(succeeded(control,expected)
             and control["x"]["pre_actual"]==[["1","-1","0"]],
             "original Native BF98 control/reference/x stack disagrees")
        pairs=[]
        for delta in (-1,-2):
            interrupted=run(source,raw,delta,"none")
            direction=run(source,raw,delta,"direction")
            full=run(source,raw,delta,"full")
            need(interrupted["status"]=="step-limit"
                 and interrupted["steps"]==BOUND+1,
                 "unrescued Native u mutant did not reproduce bounded divergence")
            need(all(x["u"]["tick"]==control["u"]["tick"] and
                     x["x"]["tick"]==control["x"]["tick"]
                     for x in (interrupted,direction,full)),
                 "Native actual u or x timing differed before intervention")
            need(interrupted["x"]["post_delta"]==[-1+delta,0]
                 and direction["x"]["post_delta"]==[-1,0]
                 and full["x"]["post_delta"]==[-1,0],
                 "intervened BF98 x vector did not match operand correction")
            dgood=succeeded(direction,expected)
            fgood=succeeded(full,expected)
            pairs.append({"u_delta":delta,"mutant":interrupted,
                          "direction_only":direction,"full_x_input":full,
                          "direction_reference_restored":dgood,
                          "full_x_reference_restored":fgood})
            print("NATIVE_U_X_TWO_CHANNEL_MEDIATION_MEASURED",label,"delta",delta,
                  "vector_rescue_output",dgood,"both_inputs_output",fgood,
                  "vector_status",direction["status"],
                  "both_status",full["status"])
            sys.stdout.flush()
        records.append({"case":label,"reference_7":expected,
                        "control":control,"pairs":pairs})
    report={"schema":"befunge-stage1-real-u-x-two-channel-mediation-v2",
            "scope":"THREE_VALID_NATIVE_INPUTS_DIRECTION_ONLY_VS_TWO_STACK_CELLS",
            "source_git_blob":PIN,"native_executions":21,
            "independent_native_references":3,
            "last_completed_stage":0,"stage1_complete":False,
            "geometric_spaghetti_qa_pass":False,
            "production_modified":False,"records":records}
    with open(OUT+"/native_real_u_x_mediation.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_BF98_U_X_TWO_CHANNEL_TWENTY_ONE_EXECUTIONS_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
