#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98: intervene in each of the three live TOSS payload slots before u.

These are runtime operand experiments. Real PyFunge executes the intact u
opcode and the complete original program. Seven-field numeric oracles are
executed as independent native Befunge-98, not calculated by Python.
"""
from __future__ import print_function
import hashlib,json,os,StringIO,sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as reference
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SOURCE="src/interleaved_work_counts.b98"
TARGET=(954,1328)
CASES=("zero_equal","forward_short","recent_anchor_next")
OUT="/u-payload"
LIMIT=210000
def need(x,m):
    if not x:raise AssertionError(m)
class Limit(Exception):pass
def stacks(ip):return [[str(int(z)) for z in layer] for layer in ip.stack]
def execute(source,raw,slot):
    stdout=StringIO.StringIO()
    program=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=stdout))
    program.load_code(source);program.create_ip()
    old=program.execute_step;tick=[0];u=[None];tail=[]
    def step(self):
        tick[0]+=1
        if tick[0]>LIMIT:raise Limit("u payload Native counterfactual bounded")
        need(len(self.ips)==1,"u payload must remain single Native IP")
        ip=self.ips[0];pos=tuple(map(int,ip.position))
        if pos==TARGET and u[0] is None:
            need(self.space.get(ip.position)==ord("u") and
                 not ip.stringmode and len(ip.stack)==2 and
                 len(ip.stack[0])==3,
                 "Native BF98 executed u and stack preconditions failed")
            pre=stacks(ip)
            if slot is not None:ip.stack[0][slot]=int(ip.stack[0][slot])+1
            after_change=stacks(ip)
            result=old()
            need(self.ips and self.ips[0] is ip,
                 "Native u unexpectedly changed IP identity")
            u[0]={"tick":tick[0],"position":list(TARGET),
                  "opcode":"u","changed_slot":slot,
                  "pre_original":pre,"pre_executed":after_change,
                  "post_executed":stacks(ip)}
            return result
        if u[0] is not None and len(tail)<128:
            tail.append([pos[0],pos[1],int(ip.delta[0]),int(ip.delta[1])])
        return old()
    program.execute_step=step.__get__(program,program.__class__)
    status="normal"
    try:program.execute()
    except Limit:status="step-limit"
    finally:del program.execute_step
    need(u[0] is not None and len(tail)==128,
         "Native u or subsequent physical route witness incomplete")
    return {"status":status,"steps":tick[0],
            "ips":len(program.ips),
            "output":stdout.getvalue().split(),"u":u[0],
            "next_128_directed_motions":tail}
def main():
    need(os.path.isdir(OUT),"missing Native u payload evidence volume")
    source=open(SOURCE,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()==PIN,
         "QA Befunge production source changed")
    book=dict((name,(fields,valid)) for name,fields,valid in reference.CASES)
    rows=[]
    for name in CASES:
        fields,valid=book[name]
        need(valid,"invalid Native input for u payload probe")
        raw=" ".join(map(str,fields))+"\n"
        oracle=reference.expected_for(*fields)
        baseline=execute(source,raw,None)
        need(baseline["status"]=="normal" and baseline["ips"]==0 and
             baseline["output"]==oracle and len(oracle)==7,
             "unmodified BF98 result disagrees with independent Native reference")
        mutants=[]
        for slot in (0,1,2):
            trial=execute(source,raw,slot)
            need(trial["u"]["tick"]==baseline["u"]["tick"] and
                 trial["u"]["pre_original"]==baseline["u"]["pre_original"] and
                 trial["u"]["opcode"]=="u",
                 "real Native u payload mutation changed pre-instruction state")
            effect=(trial["status"]!="normal" or trial["ips"]!=0
                    or trial["output"]!=oracle)
            row={"slot":slot,"run":trial,"final_effect":bool(effect),
                 "immediate_stack_effect":
                    trial["u"]["post_executed"]!=baseline["u"]["post_executed"],
                 "next_128_route_effect":
                    trial["next_128_directed_motions"]!=
                    baseline["next_128_directed_motions"]}
            mutants.append(row)
            print("NATIVE_U_TOSS_PAYLOAD_SLOT_CAUSAL",name,"slot",slot,
                  "original",baseline["u"]["pre_original"][0][slot],
                  "mutated",trial["u"]["pre_executed"][0][slot],
                  "immediate",row["immediate_stack_effect"],
                  "route",row["next_128_route_effect"],
                  "final",row["final_effect"],"status",trial["status"])
            sys.stdout.flush()
        rows.append({"case":name,"reference_7":oracle,
                     "baseline":baseline,"mutations":mutants})
    d={"schema":"befunge-stage1-native-u-live-payload-slots-v1",
       "scope":"THREE_NATIVE_INPUTS_ALL_THREE_U_TOSS_SLOTS_PLUS_ONE",
       "source_git_blob":PIN,"native_executions":12,
       "records":rows,"last_completed_stage":0,"stage1_complete":False,
       "geometric_spaghetti_qa_pass":False,"production_modified":False}
    with open(OUT+"/native_u_payload_slot_matrix.json","wb") as f:
        f.write(json.dumps(d,indent=2,sort_keys=True)+"\n")
    print("NATIVE_REAL_BF98_U_PAYLOAD_12_EXECUTIONS_9_MUTATIONS_MEASURED")
if __name__=="__main__":main()
