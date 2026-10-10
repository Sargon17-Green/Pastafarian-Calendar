#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Test-only Native BF98 causal controls for actually executed w { u }.
Mutate ONE executed Funge-space opcode into ':' and restore immediately.
Numerical expected values come solely from independent BF98 reference.
"""
from __future__ import print_function
import hashlib,json,os,StringIO,sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as reference
SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
ROOT="/opcode-causal"
CASES=("zero_equal","forward_short","recent_anchor_next")
SITES=(("w",(951,1332)),("{",(954,1330)),("u",(954,1328)),("}",(954,1322)))
def need(v,message):
    if not v:raise AssertionError(message)
class Bound(Exception):pass
def execute(code,raw,site,alter):
    out=StringIO.StringIO()
    prog=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=out))
    prog.load_code(code);prog.create_ip()
    old=prog.execute_step;ticks=[0];observed=[None]
    name,coord=site
    def one_step(self):
        ticks[0]+=1
        if ticks[0]>150000:raise Bound("Native opcode counterfactual bound")
        need(len(self.ips)==1,"unexpected multi-IP")
        ip=self.ips[0]
        if tuple(map(int,ip.position))==coord and observed[0] is None:
            char=int(self.space.get(ip.position))
            need(char==ord(name) and not ip.stringmode,
                 "pinned executed opcode or string mode changed")
            observed[0]={"tick":ticks[0],"coordinate":list(coord),
                         "original":name,"executed":":" if alter else name,
                         "mutated":bool(alter),"toss_depth":len(ip.stack[0]),
                         "frames":len(ip.stack)}
            if alter:
                self.space.put(ip.position,ord(":"))
                try:return old()
                finally:self.space.put(ip.position,char)
        return old()
    prog.execute_step=one_step.__get__(prog,prog.__class__)
    status="normal"
    try:prog.execute()
    except Bound:status="step-limit"
    finally:del prog.execute_step
    need(observed[0] is not None,"real Native opcode never executed")
    return {"status":status,"steps":ticks[0],"ips":len(prog.ips),
            "output":out.getvalue().split(),"site":observed[0]}
def main():
    need(os.path.isdir(ROOT),"evidence mount absent")
    code=open(SOURCE,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(code),code)).hexdigest()==PIN,
         "QA production source identity changed")
    book=dict((n,(f,v)) for n,f,v in reference.CASES)
    rows=[]
    for label in CASES:
        fields,valid=book[label]
        need(valid,"input must be valid")
        raw=" ".join(map(str,fields))+"\n"
        expected=reference.expected_for(*fields)
        need(len(expected)==7,"independent Native reference incomplete")
        for site in SITES:
            a=execute(code,raw,site,False)
            b=execute(code,raw,site,True)
            need(a["status"]=="normal" and a["ips"]==0 and a["output"]==expected,
                 "unmodified Native production diverged from BF98 reference")
            x,y=a["site"],b["site"]
            need(x["tick"]==y["tick"] and
                 x["coordinate"]==y["coordinate"] and
                 x["toss_depth"]==y["toss_depth"] and
                 x["frames"]==y["frames"] and
                 x["executed"]==site[0] and y["executed"]==":" and
                 x["mutated"] is False and y["mutated"] is True,
                 "native one-instruction intervention not isolated")
            effect=b["status"]!="normal" or b["ips"]!=0 or b["output"]!=expected
            rows.append({"case":label,"opcode":site[0],
                         "reference":expected,"control":a,"mutant":b,
                         "effect":bool(effect)})
            print("NATIVE_EXECUTED_SPAGHETTI_OPCODE_CAUSAL",
                  label,site[0],x["tick"],bool(effect),b["status"])
            sys.stdout.flush()
    need(len(rows)==12,"Native opcode experiment not fully populated")
    totals=dict((c,sum(1 for r in rows if r["opcode"]==c and r["effect"]))
                for c,_ in SITES)
    report={"schema":"stage1-native-executed-opcode-causality-v1",
            "source_git_blob":PIN,"sampled_cases":list(CASES),
            "real_native_programs":24,"pairs":12,
            "production_modified":False,"last_completed_stage":0,
            "stage1_complete":False,"geometry_full_pass":False,
            "effects":totals,"records":rows}
    with open(ROOT+"/opcode_causal.json","wb") as f:
        f.write(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_EXECUTED_OPCODE_CAUSAL_MATRIX_12_PAIRS_MEASURED_STAGE1_OPEN",totals)
if __name__=="__main__":main()
