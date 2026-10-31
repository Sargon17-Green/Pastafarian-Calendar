#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31B: measure actual pre-j stack in two original Native input-origin routes.
No IP relocation, source editing, or input->stack causal claim.
"""
from __future__ import print_function
import os, sys, json, gzip, hashlib, StringIO
import stage1_qa20_native_input_route_scan as qa20

SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA31A_SHA="39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c"
CASES={
 "valid00":(0,"782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a",9607,17387,61,176),
 "invalid18":(1,"9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd",1455,1672,0,115)}
def need(ok,msg):
 if not ok: raise AssertionError(msg)
def sha(raw): return hashlib.sha256(raw).hexdigest()
def qa31a_check(path):
 raw=open(path,"rb").read()
 need(sha(raw)==QA31A_SHA,"QA31A original signed JSON SHA drift")
 d=json.loads(raw)
 need(d["original_native_programs"]==136 and d["original_native_steps"]==4513423
      and d["forged_manifest_and_step_edges_rejected"]==70 and d["stage1_complete"] is False,
      "QA31A original finite audit identity mismatch")
 near=d["per_original_unobserved_target"]["113,32"]["nearest_control_state_examples"]
 matching=[x for x in near if x["position"]==[114,38] and x["runtime_opcode"]==106]
 need(len(matching)==1 and matching[0]["different_input_outcomes_observed"] is True,
      "QA31A observed differential j frontier missing")
 for label in CASES:
  tick=CASES[label][2]
  need(any(w["input"]=="QA20:"+label and w["tick"]==tick
           for outcome in matching[0]["outcomes"] for w in outcome["witnesses"]),
       "QA31A signed input-origin witness missing "+label)
def replay(root,label,source):
 shard,manifest_sha,want_tick,want_steps,want_operand,want_x=CASES[label]
 folder=os.path.join(root,label)
 raw=open(os.path.join(folder,"qa20_manifest.json"),"rb").read()
 need(sha(raw)==manifest_sha,"original QA20 manifest SHA mismatch")
 manifest=json.loads(raw)
 need(manifest["source_git_blob"]==SOURCE and manifest["shard"]==shard
      and manifest["source_modified"] is False and manifest["ip_relocated"] is False
      and manifest["stage1_final_acceptance"] is False,"signed original route provenance")
 rec=[r for r in manifest["records"] if r["label"]==label]
 need(len(rec)==1,"missing original QA20 case")
 rec=rec[0]
 need(rec["steps"]==want_steps and rec["output"]==rec["expected"]
      and rec["natural_ip_no_intervention"] is True,"original Native case changed")
 data=open(os.path.join(folder,rec["path"]),"rb").read()
 need(sha(data)==rec["compressed_trace_sha256"]
      and len(data)==rec["compressed_bytes"],"complete original Native STEP hash")
 rows=gzip.GzipFile(fileobj=StringIO.StringIO(data),mode="rb").read().splitlines()
 signed=[tuple(map(int,line.split("\t"))) for line in rows]
 need(len(signed)==want_steps and all(len(r)==7 and r[0]==i for i,r in enumerate(signed,1)),
      "original Native full STEP history invalid")
 need(signed[want_tick-1]==(want_tick,114,38,1,0,106,0)
      and signed[want_tick][1:5]==(want_x,38,1,0),
      "original signed j before/after changed")
 item=qa20.create_program(source,rec["raw_input"],label)
 program=item["program"]; witness=None
 while program.ips:
  need(len(program.ips)==1,"Native route unexpectedly multi-IP")
  tick=item["steps"]+1
  need(tick<=len(signed),"Native ran beyond signed trace")
  ip=program.ips[0]
  step=(tick,int(ip.position[0]),int(ip.position[1]),
        int(ip.delta[0]),int(ip.delta[1]),int(program.space.get(ip.position)),
        int(bool(ip.stringmode)))
  need(step==signed[tick-1],"Native signed physical step mismatch "+label+" "+str(tick))
  if tick==want_tick:
   stack=ip.stack
   need(len(stack)>0 and len(stack)<100 and not stack.queuemode and not stack.invertmode,
        "unexpected Native stack mode at j")
   pre=list(stack[-1])
   need(len(pre)<100000,"Native pre-j stack unbounded")
   operand=int(pre[-1] if pre else 0)
   need(operand==want_operand,"actual pre-j operand not expected")
  qa20.tick_qa20(item)
  if tick==want_tick:
   need(len(program.ips)==1 and program.ips[0] is ip,"original Native j replaced IP")
   post=list(ip.stack[-1])
   need(post==(pre[:-1] if pre else []),"Native j operand was not popped exactly once")
   nextip=program.ips[0]
   nextstep=(tick+1,int(nextip.position[0]),int(nextip.position[1]),
             int(nextip.delta[0]),int(nextip.delta[1]),
             int(program.space.get(nextip.position)),int(bool(nextip.stringmode)))
   need(nextstep==signed[tick] and nextstep[1]-114==operand+1,
        "Native j successor does not match direct stack operand")
   need(witness is None,"multiple j witnesses")
   witness={"tick":tick,"pre_step":list(step),"next_step":list(nextstep),
            "pre_toss":pre,"post_toss":post,"stack_stack_depth":len(ip.stack),
            "operand":operand,"physical_dx":nextstep[1]-114,
            "queue_mode":False,"invert_mode":False}
 need(item["steps"]==want_steps and witness is not None
      and item["stdout"].getvalue().split()==rec["output"],"incomplete Native replay")
 return {"label":label,"shard":shard,"raw_input":rec["raw_input"],
         "original_trace_sha256":rec["compressed_trace_sha256"],
         "steps":want_steps,"output":rec["output"],"witness":witness}
def main(root,qa31a):
 qa31a_check(qa31a)
 source=open(qa20.SOURCE,"rb").read()
 need(qa20.pin(source)==SOURCE==qa20.PIN,"original production blob changed")
 records=[replay(root,label,source) for label in ("valid00","invalid18")]
 need(sum(r["steps"] for r in records)==19059,"original total STEP count changed")
 report={"schema":"qa31b-native-original-pre-j-stack-v1","qa31a_sha256":QA31A_SHA,
         "source_git_blob":SOURCE,"original_native_cases":2,"native_steps":19059,
         "no_ip_relocation":True,"no_source_modification":True,
         "input_causality_proven":False,"stage1_complete":False,"records":records}
 with open(os.path.join(root,"qa31b_native_pre_j.json"),"wb") as f:
  f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
 print("QA31B_NATIVE_FULL_SIGNED_PARITY",19059)
 print("QA31B_MEASURED_J_OPERANDS",records[0]["witness"]["operand"],records[1]["witness"]["operand"])
 print("QA31B_INPUT_CAUSALITY_NOT_PROVEN_STAGE1_OPEN")
if __name__=="__main__":
 need(len(sys.argv)==3,"usage: qa31b ROOT ACCEPTED_QA31A_JSON")
 main(sys.argv[1],sys.argv[2])
