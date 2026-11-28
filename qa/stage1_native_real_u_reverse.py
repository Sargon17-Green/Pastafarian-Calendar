#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real Native BF98 arithmetic stack-stack u reverse-count interventions.

Live in-memory first TOSS slot changes from 1 to 0 and -1 at the exact
executed u. Compare full seven-field output/termination against original
Befunge-98 independent oracle. No source files or production are changed.
"""
from __future__ import print_function
import hashlib,json,os,StringIO,sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as ref

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
TARGET=(954,1328)
CASES=("zero_equal","forward_short","recent_anchor_next")
CHANGES=(0,-1,-2)
BOUND=170000
ROOT="/u-reverse"
def need(q,s):
    if not q:raise AssertionError(s)
class Budget(Exception):pass
def stacks(ip):
    return [[str(int(v)) for v in frame] for frame in ip.stack]
def execute(source,raw,delta):
    out=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=out))
    p.load_code(source);p.create_ip()
    old=p.execute_step;tick=[0];event=[None];post_route=[]
    def step(self):
        tick[0]+=1
        if tick[0]>BOUND:raise Budget("bounded native u reverse-count experiment")
        need(len(self.ips)==1,"unexpected Native IP concurrency")
        ip=self.ips[0];point=tuple(map(int,ip.position))
        if point==TARGET and event[0] is None:
            need(int(self.space.get(ip.position))==ord("u")
                 and not ip.stringmode and len(ip.stack)==2
                 and stacks(ip)==[["1","0","0"],["3"]],
                 "real Native u initial physical stack changed")
            before=stacks(ip)
            if delta:ip.stack[0][0]=int(ip.stack[0][0])+delta
            executed=stacks(ip)
            result=old()
            need(self.ips and self.ips[0] is ip,
                 "Native u unexpectedly changed executing IP")
            event[0]={"tick":tick[0],"position":list(TARGET),
                      "opcode":"u","first_slot_before":1,
                      "first_slot_executed":1+delta,"delta":delta,
                      "stacks_before":before,"stacks_executed":executed,
                      "stacks_after":stacks(ip)}
            return result
        if event[0] is not None and len(post_route)<128:
            post_route.append([point[0],point[1],
                               int(ip.delta[0]),int(ip.delta[1])])
        return old()
    p.execute_step=step.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except Budget:status="step-limit"
    finally:del p.execute_step
    need(event[0] is not None and len(post_route)==128,
         "real Native u and subsequent physical IP route missing")
    return {"status":status,"steps":tick[0],
            "ips":len(p.ips),"output":out.getvalue().split(),
            "u_event":event[0],"first_128_post_u_route":post_route}
def main():
    need(os.path.isdir(ROOT),"missing Native u-reverse evidence mount")
    original=open(SOURCE,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(original),original)).hexdigest()==PIN,
         "Native QA source no longer exact pinned version")
    book=dict((n,(f,v)) for n,f,v in ref.CASES)
    records=[]
    for name in CASES:
        fields,valid=book[name]
        need(valid,"u reverse experiment must test legal input")
        raw=" ".join(map(str,fields))+"\n"
        oracle=ref.expected_for(*fields)
        baseline=execute(original,raw,0)
        need(baseline["status"]=="normal" and baseline["ips"]==0
             and baseline["output"]==oracle and len(oracle)==7,
             "original native u control disagrees with independent BF98")
        trials=[]
        for delta in (-1,-2):
            mut=execute(original,raw,delta)
            need(mut["u_event"]["tick"]==baseline["u_event"]["tick"]
                 and mut["u_event"]["stacks_before"]==
                      baseline["u_event"]["stacks_before"]
                 and mut["u_event"]["stacks_executed"]!=
                      baseline["u_event"]["stacks_executed"],
                 "real Native counterfactual not one-site isolated")
            effect=mut["status"]!="normal" or mut["ips"]!=0 or mut["output"]!=oracle
            trials.append({"delta":delta,"run":mut,
                           "final_output_or_termination_changed":bool(effect),
                           "terminated_normally":mut["status"]=="normal" and mut["ips"]==0,
                           "numerical_output_changed":mut["output"]!=oracle,
                           "immediate_stack_difference":
                               mut["u_event"]["stacks_after"]!=
                               baseline["u_event"]["stacks_after"],
                           "post128_route_difference":
                               mut["first_128_post_u_route"]!=
                               baseline["first_128_post_u_route"]})
            print("NATIVE_REAL_U_REVERSE_COUNT",name,"delta",delta,
                  "count_before",1,"count_executed",1+delta,
                  "steps",mut["steps"],"status",mut["status"],
                  "numeric_change",trials[-1]["numerical_output_changed"],
                  "route_change",trials[-1]["post128_route_difference"])
            sys.stdout.flush()
        records.append({"case":name,"reference_7":oracle,
                        "baseline":baseline,"trials":trials})
    d={"schema":"befunge-stage1-native-u-reverse-count-v1",
       "scope":"THREE_VALID_NATIVE_INPUTS_U_FIRST_TOSS_SLOT_REDUCED",
       "source_git_blob":PIN,"native_executions":9,
       "stage1_complete":False,"last_completed_stage":0,
       "geometric_spaghetti_qa_pass":False,"production_modified":False,
       "records":records}
    with open(ROOT+"/u_reverse_native_evidence.json","wb") as f:
        f.write(json.dumps(d,indent=2,sort_keys=True)+"\n")
    print("NATIVE_BF98_U_REVERSE_COUNT_NINE_PROGRAMS_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
