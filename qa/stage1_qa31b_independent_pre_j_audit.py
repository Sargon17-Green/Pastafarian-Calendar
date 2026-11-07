#!/usr/bin/env python3
"""Independent QA31B signed-origin and adversarial stack-receipt audit.
Original STEP traces certify geometry but not hidden stack contents;
native instrumentation independently samples actual stack before j.
"""
import sys,os,json,hashlib,gzip,copy
from pathlib import Path
SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA31A="39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c"
CASES={
 "valid00":(0,"782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a",9607,17387,61,176),
 "invalid18":(1,"9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd",1455,1672,0,115)}
def need(ok,msg):
 if not ok:raise AssertionError(msg)
def sha(x):return hashlib.sha256(x).hexdigest()
def verify(rec,label,root):
 shard,pin,tick,steps,op,x=CASES[label]
 folder=Path(root)/label;raw=(folder/"qa20_manifest.json").read_bytes()
 need(sha(raw)==pin,"original manifest changed")
 manifest=json.loads(raw)
 need(manifest["source_git_blob"]==SOURCE and manifest["shard"]==shard
      and manifest["source_modified"] is False and manifest["ip_relocated"] is False,
      "original Native provenance changed")
 rs=[r for r in manifest["records"] if r["label"]==label]
 need(len(rs)==1,"signed original input missing")
 orig=rs[0];b=(folder/orig["path"]).read_bytes()
 need(sha(b)==orig["compressed_trace_sha256"] and len(b)==orig["compressed_bytes"],
      "signed compressed original STEP record changed")
 rows=gzip.decompress(b).splitlines()
 need(len(rows)==steps==orig["steps"],"original full Native STEP count mismatch")
 before=list(map(int,rows[tick-1].split(b"\t")))
 after=list(map(int,rows[tick].split(b"\t")))
 need(before==[tick,114,38,1,0,106,0] and after[1:5]==[x,38,1,0]
      and after[0]==tick+1,"original signed Native j STEP pair changed")
 need(rec.get("label")==label and rec.get("shard")==shard
      and rec.get("raw_input")==orig["raw_input"]
      and rec.get("original_trace_sha256")==orig["compressed_trace_sha256"]
      and rec.get("steps")==steps and rec.get("output")==orig["output"]==orig["expected"],
      "Native input/output/full-step receipt changed")
 w=rec.get("witness")
 need(type(w) is dict and w.get("tick")==tick
      and w.get("pre_step")==before and w.get("next_step")==after
      and w.get("queue_mode") is False and w.get("invert_mode") is False,
      "Native stack witness detached from signed j steps")
 pre=w.get("pre_toss");post=w.get("post_toss")
 need(type(pre) is list and type(post) is list and len(pre)<100000
      and all(type(n) is int for n in pre+post)
      and post==(pre[:-1] if pre else [])
      and type(w.get("stack_stack_depth")) is int and 1<=w["stack_stack_depth"]<100,
      "Native stack consumption or stack-stack metadata corrupt")
 need(w.get("operand")==op==(pre[-1] if pre else 0)
      and w.get("physical_dx")==after[1]-114==op+1,
      "Native direct j operand inconsistent with physical signed jump")
def controls(row,label,root):
 attacks=[
 ("operand",lambda r:r["witness"].__setitem__("operand",999)),
 ("pre-stack",lambda r:r["witness"]["pre_toss"].append(999)),
 ("post-stack",lambda r:r["witness"]["post_toss"].append(999)),
 ("stack-depth",lambda r:r["witness"].__setitem__("stack_stack_depth",0)),
 ("queue",lambda r:r["witness"].__setitem__("queue_mode",True)),
 ("invert",lambda r:r["witness"].__setitem__("invert_mode",True)),
 ("pre-ip",lambda r:r["witness"]["pre_step"].__setitem__(1,999)),
 ("post-ip",lambda r:r["witness"]["next_step"].__setitem__(1,999)),
 ("tick",lambda r:r["witness"].__setitem__("tick",0)),
 ("dx",lambda r:r["witness"].__setitem__("physical_dx",7)),
 ("input",lambda r:r.__setitem__("raw_input","0 0 9 9\n")),
 ("trace-sha",lambda r:r.__setitem__("original_trace_sha256","0"*64)),
 ("steps",lambda r:r.__setitem__("steps",1)),
 ("output",lambda r:r.__setitem__("output",["42"]*7))]
 for name,mutate in attacks:
  fake=copy.deepcopy(row);mutate(fake)
  try:verify(fake,label,root)
  except (AssertionError,TypeError,ValueError,IndexError,KeyError):pass
  else:raise AssertionError("forged receipt accepted: "+label+" "+name)
 return len(attacks)
def main(source,qa31a,root,native,output):
 src=Path(source).read_bytes()
 need(hashlib.sha1(b"blob "+str(len(src)).encode()+b"\0"+src).hexdigest()==SOURCE,
      "production source blob changed")
 b=Path(qa31a).read_bytes();need(sha(b)==QA31A,"QA31A original SHA changed")
 d=json.loads(b)
 need(d["original_native_programs"]==136 and d["original_native_steps"]==4513423
      and d["forged_manifest_and_step_edges_rejected"]==70
      and d["stage1_complete"] is False,"QA31A scope changed")
 r=json.loads(Path(native).read_bytes())
 need(r.get("schema")=="qa31b-native-original-pre-j-stack-v1"
      and r.get("qa31a_sha256")==QA31A and r.get("source_git_blob")==SOURCE
      and r.get("original_native_cases")==2 and r.get("native_steps")==19059
      and r.get("no_ip_relocation") is True and r.get("no_source_modification") is True
      and r.get("input_causality_proven") is False and r.get("stage1_complete") is False,
      "QA31B falsely claimed global/input causality or Stage1 acceptance")
 rows=r.get("records")
 need(type(rows) is list and [x.get("label") for x in rows]==["valid00","invalid18"],
      "QA31B missing original two cases")
 count=0
 for rec in rows:
  verify(rec,rec["label"],root)
  count+=controls(rec,rec["label"],root)
 need(count==28,"adversarial receipt coverage changed")
 report={"schema":"qa31b-independent-pre-j-audit-v1","original_native_steps":19059,
         "forged_receipts_rejected":count,"input_causality_proven":False,
         "stage1_complete":False}
 Path(output).write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
 print("QA31B_INDEPENDENT_ORIGINAL_TRACE_AUDIT",19059)
 print("QA31B_INDEPENDENT_FORGERIES_REJECTED",count)
 print("QA31B_INPUT_TO_STACK_CAUSALITY_UNPROVEN")
if __name__=="__main__":
 need(len(sys.argv)==6,"usage: auditor SOURCE QA31A ROOT NATIVE OUT")
 main(*sys.argv[1:])
