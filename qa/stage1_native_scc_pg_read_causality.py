#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA only: intervene at real Native BF98 arithmetic-SCC g read after p write."""
from __future__ import print_function
import hashlib,json,os,StringIO,sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as ref
SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT="/scc-causality"
P=(1249,1050);G=(575,1164);CELL=(37,1700)
NAMES=("forward_short","mixed_small","foundation_cross")
def check(condition,message):
    if not condition:raise AssertionError(message)
class Limit(Exception):pass
def live(source,raw,change):
    output=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=output))
    p.load_code(source);p.create_ip()
    target=p.ips[0].position.__class__(CELL)
    old=p.execute_step;tick=[0];wrote=[None];read=[None]
    def step(self):
        tick[0]+=1
        if tick[0]>750000:raise Limit()
        check(len(self.ips)==1,"unexpected Native multiple-IP execution")
        ip=self.ips[0];at=tuple(map(int,ip.position))
        if at==P and wrote[0] is None:
            stack=list(ip.stack[0])
            check(self.space.get(ip.position)==ord("p") and
                  len(stack)>=3 and tuple(map(int,stack[-2:]))==CELL,
                  "Native p physical write site mismatch")
            original=old()
            value=int(stack[-3])
            check(int(self.space.get(target))==value,"Native p write absent")
            wrote[0]={"tick":tick[0],"value":value}
            return original
        if at==G and read[0] is None:
            stack=list(ip.stack[0])
            check(self.space.get(ip.position)==ord("g") and
                  len(stack)>=2 and tuple(map(int,stack[-2:]))==CELL and
                  wrote[0] is not None,"Native g first SCC read missing")
            prior=int(self.space.get(target))
            check(prior==wrote[0]["value"],"real p/g lineage changed")
            got=prior+1 if change else prior
            if change:self.space.put(target,got)
            result=old()
            check(self.ips and self.ips[0] is ip and ip.stack[0] and
                  int(ip.stack[0][-1])==got,"real Native g did not return injected byte")
            read[0]={"p_tick":wrote[0]["tick"],"g_tick":tick[0],
                     "written":prior,"returned":int(ip.stack[0][-1]),
                     "injected":bool(change),"physical_cell":list(CELL)}
            return result
        return old()
    p.execute_step=step.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except Limit:status="step-limit"
    finally:del p.execute_step
    check(read[0] is not None,"real Native SCC g not executed")
    return {"status":status,"steps":tick[0],"remaining_ips":len(p.ips),
            "output":output.getvalue().split(),"read":read[0]}
def main():
    check(os.path.isdir(OUT),"Native SCC result volume missing")
    source=open(SOURCE,"rb").read()
    check(hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()==PIN,
          "production QA source blob unpinned")
    cases=dict((name,(fields,valid)) for name,fields,valid in ref.CASES)
    rows=[]
    for name in NAMES:
        fields,valid=cases[name]
        check(valid,"invalid native control")
        raw=" ".join(map(str,fields))+"\n"
        expected=ref.expected_for(*fields)
        a=live(source,raw,False);b=live(source,raw,True)
        check(a["status"]=="normal" and a["remaining_ips"]==0 and
              a["output"]==expected and len(expected)==7,
              "untouched real Native output fails independent BF98 oracle")
        x=a["read"];y=b["read"]
        check(x["p_tick"]==y["p_tick"] and x["g_tick"]==y["g_tick"] and
              x["written"]==y["written"] and x["returned"]==x["written"] and
              y["returned"]==x["written"]+1 and
              not x["injected"] and y["injected"],
              "physical Native g interception was not isolated")
        changed=b["status"]!="normal" or b["remaining_ips"]!=0 or b["output"]!=expected
        rows.append({"case":name,"reference_7":expected,
                     "control":a,"mutant":b,"final_effect":changed})
        print("NATIVE_SCC_PG_CAUSAL_PAIR",name,"from",x["returned"],
              "to",y["returned"],"final_effect",changed)
        sys.stdout.flush()
    d={"schema":"befunge-stage1-scc-real-pg-causal-v1","source_git_blob":PIN,
       "qa_only":True,"last_completed_stage":0,"stage1_complete":False,
       "read_cell":list(CELL),"p_site":list(P),"g_site":list(G),
       "native_executions":6,"records":rows,
       "causal_effect_pairs":sum(r["final_effect"] for r in rows)}
    with open(OUT+"/native_scc_real_pg_causal.json","wb") as output:
        output.write(json.dumps(d,indent=2,sort_keys=True)+"\n")
    print("NATIVE_SCC_PG_CAUSAL_THREE_PAIRS_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
