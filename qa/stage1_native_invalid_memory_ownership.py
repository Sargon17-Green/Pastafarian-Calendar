#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 QA: 21 invalid-input native memory traces, no Python arithmetic."""
from __future__ import print_function
import json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
NUMERIC=["1 0 0 0","0 0 1 0","2 10 0 10",
         "0 10 2 10","3 2 0 4","1 0 1 15055671"]
LEXICAL=["0 -1 0 1","-0 1 0 1","0 1 -0 1",
         "0 1 0 -1","0 -0 0 1","0 0 0 -0",
         "0 -15055671 0 1","0 15055671 0 -15055670",
         "0 1 0 1 7","0 1 0","0 1 0 x",
         "0 1 0 1/","","\n","0 1 0 +1"]
def need(ok,reason):
    if not ok:raise AssertionError(reason)
class Limit(Exception):pass

def run(source,lines,kind,i,raw):
    stream=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw+"\n"),stdout=stream))
    p.load_code(source);p.create_ip()
    space=p.space;cls=type(space)
    orig_put,orig_putspace,orig_step=cls.put,cls.putspace,p.execute_step
    ticks=[0];writes=[];reads=[];ks=[];putspace=[];last={};direct=[]
    def sourceval(point):
        x,y=point
        return ord(lines[y][x]) if 0<=y<len(lines) and 0<=x<len(lines[y]) else 32
    def wrapped_put(self,*args,**kwargs):
        need(self is space and len(args)>=2 and len(p.ips)==1,
             "unexpected Native put context")
        ip=p.ips[0];xy=list(map(int,ip.position));op=int(self.get(ip.position))
        point=args[0];target=list(map(int,point))
        result=orig_put(self,*args,**kwargs)
        value=int(self.get(point))
        need(value==int(args[1]),"actual native put did not store value")
        writes.append({"tick":ticks[0],"ip":xy,"opcode":op,
                       "target":target,"value":value})
        last[tuple(target)]=(len(writes)-1,value)
        return result
    def wrapped_putspace(self,*args,**kwargs):
        need(self is space,"unrecognized native putspace target")
        putspace.append(ticks[0])
        return orig_putspace(self,*args,**kwargs)
    def step(self):
        ticks[0]+=1
        if ticks[0]>fork.BOUND:raise Limit()
        need(len(self.ips)==1,"unexpected Native IP multiplicity")
        ip=self.ips[0];xy=tuple(map(int,ip.position))
        op=int(self.space.get(ip.position));pending=None
        if not ip.stringmode and op==ord("p"):
            direct.append(ticks[0])
        if not ip.stringmode and op==ord("k"):
            delta=tuple(map(int,ip.delta))
            target=(xy[0]+delta[0],xy[1]+delta[1])
            nextbyte=int(self.space.get(ip.position.__class__(target)))
            ks.append({"tick":ticks[0],"ip":list(xy),
                       "target":list(target),"nextbyte":nextbyte})
            need(nextbyte not in (ord("p"),ord("g")),
                 "executed k dispatches hidden native p/g")
        if not ip.stringmode and op==ord("g"):
            operands=list(ip.stack[0])[-2:]
            while len(operands)<2:operands.insert(0,0)
            x,y=map(int,operands)
            target=(x+int(ip.offset[0]),y+int(ip.offset[1]))
            actual=int(self.space.get(ip.position.__class__(target)))
            prior=last.get(target);expected=prior[1] if prior else sourceval(target)
            need(actual==expected,"native g disagrees with put history/source")
            pending={"tick":ticks[0],"ip":list(xy),"target":list(target),
                     "value":actual,"source_value":sourceval(target),
                     "last_p_index":prior[0] if prior else -1}
        result=orig_step()
        if pending is not None:
            need(self.ips and self.ips[0] is ip and ip.stack[0] and
                 int(ip.stack[0][-1])==pending["value"],
                 "native g result differs from observed memory")
            pending["returned"]=int(ip.stack[0][-1]);reads.append(pending)
        return result
    try:
        cls.put=wrapped_put;cls.putspace=wrapped_putspace
        p.execute_step=step.__get__(p,p.__class__)
        state="normal"
        try:p.execute()
        except Limit:state="step-limit"
    finally:
        if "execute_step" in p.__dict__:del p.execute_step
        cls.put=orig_put;cls.putspace=orig_putspace
    output=stream.getvalue().split()
    need(state=="normal" and len(p.ips)==0 and output==["-1"]*7,
         "rejected Native input did not yield 7 sentinels")
    need(not putspace and len(writes)==len(direct) and
         all(z["opcode"]==ord("p") for z in writes) and
         [z["tick"] for z in writes]==direct,
         "unexpected invalid-path memory mutation")
    print("NATIVE_INVALID_MEMORY_CASE_PASS",kind,i,
          "p",len(writes),"g",len(reads),"k",len(ks));sys.stdout.flush()
    return {"kind":kind,"index":i,"raw":raw,"ticks":ticks[0],
            "status":state,"remaining_ips":len(p.ips),"output":output,
            "puts":writes,"gets":reads,"ks":ks,"putspace":putspace,
            "direct_p_count":len(direct)}
def main():
    need(os.path.isdir("/invalid"),"Native evidence output not mounted")
    src=open("src/interleaved_work_counts.b98","rb").read()
    need(fork.blob(src)==PIN,"QA source blob mismatch")
    lines=src.split("\n");records=[]
    for i,raw in enumerate(NUMERIC):
        records.append(run(src,lines,"numeric",i,raw))
    for i,raw in enumerate(LEXICAL):
        records.append(run(src,lines,"lexical",i,raw))
    need(len(records)==21,"Native invalid corpus incomplete")
    report={"schema":"befunge-stage1-invalid-memory-v1",
            "source_git_blob":PIN,"status":"QA_ONLY_STAGE1_OPEN",
            "numeric_cases":6,"lexical_cases":15,"native_runs":21,
            "native_puts":sum(len(z["puts"]) for z in records),
            "native_gets":sum(len(z["gets"]) for z in records),
            "native_k":sum(len(z["ks"]) for z in records),
            "native_putspace":sum(len(z["putspace"]) for z in records),
            "nested_k_g_proof":False,"other_apis_proven":False,
            "final_stage1_accepted":False,"records":records}
    with open("/invalid/native_invalid_memory.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_INVALID_MEMORY_21_REAL_INPUTS_PASS",
          "p",report["native_puts"],"g",report["native_gets"],
          "k",report["native_k"])
    print("LAST_COMPLETED_STAGE=0")
if __name__=="__main__":main()
