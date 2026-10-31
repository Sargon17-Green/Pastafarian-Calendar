#!/usr/bin/env python3
"""QA31H: independently link original QA31G physical p/g/j events; finite only."""
import argparse,copy,gzip,hashlib,io,json,zipfile
from pathlib import Path

SOURCE_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
ZIP_SHA="e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161"
CASES={
 "empty":(b"","8e58dc53a786f59f1825a477b212f298fdbd3dbe09a291225d2de80a8e57cab3",776),
 "digit":(b"1","018091d998f546a918575f3f3f93e07cad68bd88d5adcdf8a36663cfafdcc4aa",2046),
 "digit_space":(b"1 ","69f868bd3969b77e7640cb355c6429e73822c6845e8968d82ef2b45ecbf04ad7",3038)}
TARGETS={(3,49),(1,49)}
G29=(89,29)
G32=(113,32)
def need(ok,why):
 if not ok:raise AssertionError(why)
def sha(b):return hashlib.sha256(b).hexdigest()
def source_rows(path):
 b=Path(path).read_bytes()
 h=hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()
 need(h==SOURCE_BLOB,"source Git blob mismatch")
 return b.splitlines()
def cell(rows,point,overlay):
 if point in overlay:return overlay[point]
 x,y=point
 return rows[y][x] if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32
def trace_audit(tag,steps,rows):
 need(len(steps)==CASES[tag][2],"STEP count")
 overlay={};writers={k:[] for k in TARGETS};reads={k:[] for k in TARGETS}
 gates={G29:[],G32:[]};last_read={G29:None,G32:None}
 for i,s in enumerate(steps):
  t=i+1;ip=tuple(s["ip"]);d=tuple(s["delta"]);pre=s["pre"];post=s["post"]
  need(s["t"]==t,"STEP sequence")
  need(len(ip)==len(d)==2 and d!=(0,0),"IP/delta")
  need(s["string"] is False and s["op"]==cell(rows,ip,overlay),"source/overlay opcode")
  need(isinstance(pre,list) and isinstance(post,list) and all(type(v) is int for v in pre+post),"stack")
  if i:
   old=steps[i-1]
   need(old["next"]==s["ip"] and old["next_delta"]==s["delta"],"IP continuity")
  op=chr(s["op"])
  if op=="p":
   need(len(pre)>=3 and post==pre[:-3],"p stack")
   xy=(pre[-2],pre[-1]);value=pre[-3]
   overlay[xy]=value
   if xy in TARGETS:writers[xy].append({"t":t,"ip":list(ip),"value":value})
  if op=="g":
   need(len(pre)>=2 and len(post)==len(pre)-1 and post[:-1]==pre[:-2],"g stack")
   xy=(pre[-2],pre[-1])
   need(post[-1]==cell(rows,xy,overlay),"g value against last writer")
   if xy in TARGETS:
    w=writers[xy][-1] if writers[xy] else None
    r={"t":t,"ip":list(ip),"value":post[-1],
       "writer_t":w["t"] if w else None,"writer_value":w["value"] if w else None}
    reads[xy].append(r)
    if ip==(57,29):
     need(xy==(3,49),"g29 coordinates");last_read[G29]=r
    if ip==(57,32):
     need(xy==(1,49),"g32 coordinates");last_read[G32]=r
  if op=="j" and ip in gates:
   operand=pre[-1] if pre else 0
   need(post==(pre[:-1] if pre else []),"j stack")
   need(s["next"]==[ip[0]+(operand+1)*d[0],ip[1]+(operand+1)*d[1]],"j skip")
   r=last_read[ip]
   need(r is not None and r["t"]<t,"missing upstream g")
   xy=(3,49) if ip==G29 else (1,49)
   need(not any(r["t"]<w["t"]<=t for w in writers[xy]),"intervening write")
   need(operand==(61*r["value"] if ip==G29 else r["value"]),"gate operand")
   gates[ip].append({"t":t,"operand":operand,"read_t":r["t"],
                     "writer_t":r["writer_t"],"value":r["value"]})
  need(isinstance(s["reads"],list),"input events")
 need(steps[-1]["next"] is None and steps[-1]["op"]==64,"HALT")
 return {"steps":len(steps),"writers":{str(k):v for k,v in writers.items()},
         "reads":{str(k):v for k,v in reads.items()},
         "j29":gates[G29],"j32":gates[G32]}
def finite(f):
 e,d,s=(f[k] for k in ("empty","digit","digit_space"))
 need([v["operand"] for v in e["j29"]]==[0] and not e["j32"],"empty control")
 need([v["operand"] for v in d["j29"]]==[61] and len(d["j32"])==1
      and d["j32"][0]["operand"]==0,"digit gates")
 need([v["operand"] for v in s["j29"]]==[0] and not s["j32"],"space gate")
 for item,ticks in ((e["j29"][0],(242,389,414)),
                    (d["j29"][0],(1082,1229,1254)),
                    (s["j29"][0],(2504,2651,2676))):
  need((item["writer_t"],item["read_t"],item["t"])==ticks,"signed gate chain")
 need(d["j32"][0]["writer_t"]==146 and d["j32"][0]["read_t"]==1349,"row32 lineage")
 for fcase,expected in ((d,[(146,0),(1684,1)]),(s,[(146,0),(2408,1)])):
  need([(w["t"],w["value"]) for w in fcase["writers"]["(1, 49)"]]==expected,
       "secondary cell writes")
  need(fcase["reads"]["(1, 49)"][-1]["writer_t"]==expected[-1][0],
       "secondary cell final reader")
def signed(zip_path):
 raw=Path(zip_path).read_bytes()
 need(sha(raw)==ZIP_SHA,"QA31G ZIP SHA256")
 with zipfile.ZipFile(io.BytesIO(raw)) as z:
  need(z.testzip() is None,"ZIP CRC")
  expected={"qa31g_receipt.json","qa31g_independent.json","native.log","audit.log"}
  expected.update("qa31g_"+k+".jsonl.gz" for k in CASES)
  need(set(z.namelist())==expected,"ZIP entries")
  receipt=json.loads(z.read("qa31g_receipt.json"))
  need(receipt["schema"]=="qa31g-original-native-eof-v1" and
       receipt["source_blob"]==SOURCE_BLOB and receipt["source_modified"] is False and
       receipt["ip_relocated"] is False and receipt["stage1_pass"] is False,"provenance")
  need(len(receipt["cases"])==3,"cases count")
  traces={}
  for c in receipt["cases"]:
   tag=c["label"];need(tag in CASES and tag not in traces,"case")
   raw_input,h,num=CASES[tag];name="qa31g_"+tag+".jsonl.gz"
   need(c["raw_hex"]==raw_input.hex() and c["raw_sha256"]==sha(raw_input)
        and c["trace"]==name and c["trace_sha256"]==h
        and c["steps"]==num and c["status"]=="HALT" and c["error"] is None,
        "immutable case receipt")
   b=z.read(name);need(sha(b)==h,"trace gzip SHA256")
   traces[tag]=[json.loads(s) for s in gzip.decompress(b).splitlines()]
 need(set(traces)==set(CASES),"missing case")
 return traces
def corruptions(traces,rows):
 attacks=[
  ("remove STEP","digit",lambda a:a.pop(1228)),
  ("replace upstream g","digit",lambda a:a.__setitem__(1228,a[1080])),
  ("forge g output","digit",lambda a:a[1228]["post"].__setitem__(-1,0)),
  ("forge j operand","digit",lambda a:a[1253]["pre"].__setitem__(-1,0)),
  ("wrong j target","digit",lambda a:a[1253].__setitem__("next",[90,29])),
  ("wrong IP","digit",lambda a:a[1253].__setitem__("ip",[88,29])),
  ("drop reset p","digit_space",lambda a:a.pop(2503)),
  ("reorder reset","digit_space",lambda a:a.__setitem__(2503,a[2502])),
  ("forge second-cell p","digit",lambda a:a[1683]["pre"].__setitem__(-3,0)),
  ("forge g address","digit_space",lambda a:a[2650]["pre"].__setitem__(-2,1))]
 rejected=[]
 for title,tag,attack in attacks:
  r=copy.deepcopy(traces[tag]);attack(r)
  try:trace_audit(tag,r,rows)
  except (AssertionError,IndexError,KeyError,ValueError,TypeError):rejected.append(title)
  else:raise AssertionError("accepted physical forgery: "+title)
 need(len(rejected)==10,"forgery count")
 return rejected
def main():
 p=argparse.ArgumentParser()
 p.add_argument("source");p.add_argument("artifact_zip")
 p.add_argument("--output",default="qa31h_audit.json")
 a=p.parse_args();rows=source_rows(a.source);traces=signed(a.artifact_zip)
 facts={k:trace_audit(k,v,rows) for k,v in traces.items()}
 finite(facts);rejected=corruptions(traces,rows)
 result={"schema":"qa31h-bounded-last-writer-reader-v1",
   "source_blob":SOURCE_BLOB,"qa31g_zip_sha256":ZIP_SHA,
   "cases_verified":len(facts),
   "physical_steps_verified":sum(f["steps"] for f in facts.values()),
   "forgeries_rejected":len(rejected),"rejected_mutations":rejected,
   "native_executions_new":0,"stage1_pass":False,
   "source_ownership_global_proven":False,
   "full_functional_qa_pass":False,"geometric_spaghetti_qa_pass":False,
   "facts":facts}
 Path(a.output).write_text(json.dumps(result,indent=2,sort_keys=True)+"\n",encoding="utf-8")
 print("QA31H_SIGNED_TRACE_CASES",len(facts))
 print("QA31H_SIGNED_PHYSICAL_STEPS",result["physical_steps_verified"])
 print("QA31H_FORGERIES_REJECTED",len(rejected))
 print("QA31H_NO_NEW_NATIVE_NO_STAGE1_PASS")
if __name__=="__main__":main()
