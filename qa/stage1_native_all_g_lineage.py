#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only bounded Native PyFunge p-to-g provenance for 64 fork replays.
Every top-level executed g is checked against the last executed p or
the immutable source; arithmetic stays in the actual Befunge source.
Other memory APIs and nested k-driven commands are outside this audit.
"""
from __future__ import print_function
import json, os, sys, StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork
SRC="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def ok(cond,msg):
    if not cond: raise AssertionError(msg)
class Limit(Exception): pass
def run(code,rows,fields,ref,oracle):
    out=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(" ".join(map(str,fields))+"\n"),stdout=out))
    p.load_code(code);p.create_ip();step=p.execute_step
    tick=[0];gates=[0];writes=[];reads=[];latest={}
    def origin_at(point):
        x,y=point
        return ord(rows[y][x]) if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32
    def hook(self):
        tick[0]+=1
        if tick[0]>fork.BOUND:raise Limit()
        ok(len(self.ips)==1,"unexpected multiple real Native IPs")
        ip=self.ips[0];xy=tuple(map(int,ip.position))
        opcode=int(self.space.get(ip.position))
        if xy==fork.GATE:
            ok(opcode==ord("|") and ip.stack[0],"Native gate missing")
            cls=int(bool(ip.stack[0][-1]))
            ok(cls==ref["gate"][0],"natural fork class drift")
            if ref["opposite"]:ip.stack[0][-1]=0 if cls else 1
            gates[0]+=1
        before_p=None;before_g=None
        if not ip.stringmode and opcode in (ord("p"),ord("g")):
            vals=list(ip.stack[0]);amount=3 if opcode==ord("p") else 2
            ok(len(vals)>=amount,"Native g/p missing physical operands")
            part=list(map(int,vals[-amount:]))
            coord=(part[-2]+int(ip.offset[0]),part[-1]+int(ip.offset[1]))
            if opcode==ord("p"):
                before_p=(list(xy),list(coord),part[0],ip.position.__class__(coord))
            else:
                prev=latest.get(coord);physical=int(self.space.get(
                    ip.position.__class__(coord)))
                ok(physical==(prev[1] if prev else origin_at(coord)),
                   "Native pre-g byte not explained by p history/source")
                before_g=(list(xy),list(coord),physical,
                          prev[0] if prev else -1,origin_at(coord),ip)
        answer=step()
        if before_p:
            sourcepoint,target,value,vector=before_p
            actual=int(self.space.get(vector))
            ok(actual==value,"Native p write not physically stored")
            writes.append({"tick":tick[0],"ip":sourcepoint,"opcode":112,
                           "target":target,"value":actual})
            latest[tuple(target)]=(len(writes)-1,actual)
        if before_g:
            sourcepoint,target,physical,writer_idx,source_value,oldip=before_g
            ok(self.ips and self.ips[0] is oldip and oldip.stack[0] and
               int(oldip.stack[0][-1])==physical,
               "actual Native g did not return physical cell value")
            reads.append({"tick":tick[0],"ip":sourcepoint,"target":target,
                          "value":physical,"returned":int(oldip.stack[0][-1]),
                          "previous_p_index":writer_idx,
                          "initial_source_byte":source_value})
        return answer
    p.execute_step=hook.__get__(p,p.__class__)
    state="normal"
    try:p.execute()
    except Limit:state="step-limit"
    finally:del p.execute_step
    ok(gates[0]==1 and state==ref["status"] and
       tick[0]==ref["ticks"] and len(p.ips)==ref["remaining_ips"] and
       writes==ref["native_put_events"],
       "native replay p events not identical to engine-level Space.put")
    if not ref["opposite"]:
        ok(state=="normal" and len(p.ips)==0 and out.getvalue().split()==oracle,
           "Native unchanged result differs from independent Befunge reference")
    print("NATIVE_ALL_G_LINEAGE",ref["case"],"forced",ref["opposite"],
          "p",len(writes),"g",len(reads))
    sys.stdout.flush()
    return {"case":ref["case"],"opposite":ref["opposite"],
            "ticks":tick[0],"status":state,
            "matched_engine_put_count":len(writes),"g_reads":reads}
def main():
    ok(os.path.isdir("/writes"),"Native evidence mount missing")
    source=open(SRC,"rb").read()
    ok(fork.blob(source)==PIN,"exact Befunge git blob changed")
    old=json.load(open("/writes/native_fungespace_put_inventory.json","rb"))
    ok(old.get("production_git_blob")==PIN and len(old.get("records",[]))==64,
       "real native writer inventory incomplete")
    cases={x[0]:(x[1],x[2]) for x in fork.native.CASES}
    cases.update({x[0]:(x[1],x[2]) for x in fork.wide.CASES})
    rows=[]
    for ref in old["records"]:
        name=ref["case"]
        ok(name in cases and cases[name][1],"unrecognized valid Native case")
        args=cases[name][0];oracle=fork.native.expected_for(*args)
        rows.append(run(source,source.split("\n"),args,ref,oracle))
    count=sum(len(x["g_reads"]) for x in rows)
    prior=sum(sum(e["previous_p_index"]>=0 for e in x["g_reads"]) for x in rows)
    ok(count>0 and prior>0,"Native p/g read evidence implausibly empty")
    report={"schema":"befunge-stage1-native-all-g-lineage-v1",
            "status":"QA_ONLY_EXECUTED_TOP_LEVEL_G_LINEAGE",
            "source_git_blob":PIN,"real_programs":64,"valid_cases":32,
            "p_events_cross_checked":sum(x["matched_engine_put_count"] for x in rows),
            "g_reads":count,"p_dependent_g_reads":prior,
            "source_origin_g_reads":count-prior,
            "nested_k_g_not_excluded":True,
            "other_mutation_apis_audited":False,
            "stage1_final_accepted":False,"records":rows}
    with open("/writes/native_all_g_lineage.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_ALL_G_LINEAGE_64_REPLAYS_PASS",
          "p",report["p_events_cross_checked"],"g",count,"p_dependent",prior)
    print("STAGE1_SEMANTIC_OWNERSHIP_OPEN")
if __name__=="__main__":main()
