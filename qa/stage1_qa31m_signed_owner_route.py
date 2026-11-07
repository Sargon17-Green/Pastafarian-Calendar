#!/usr/bin/env python3
"""QA31M bounded p/g ownership on one signed original Native trace."""
import argparse, copy, hashlib, json
from pathlib import Path
from stage1_qa31m_original_native_route_audit import load_signed, audit as route_audit

BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
CROSS={(1301,(211,29),(10,32)),(1445,(174,32),(10,35)),
       (1731,(309,35),(10,38)),(1876,(175,38),(10,44))}
GATES={(1254,(89,29),61),(1398,(113,32),0),(1829,(114,38),0)}
OWNERS={(1229,(3,49),1082,1),(1349,(1,49),146,0),(1779,(1,49),1684,1)}

def req(ok,reason):
    if not ok:raise AssertionError(reason)
def source(path):
    raw=Path(path).read_bytes()
    got=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    req(got==BLOB,"pinned source blob")
    return raw.splitlines()
def cell(rows,xy):
    x,y=xy
    return rows[y][x] if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32
def check(steps,rows):
    req(len(steps)==2046,"physical count")
    overlay={};last={};writes=[];reads=[];gates=[];xs=[]
    for ix,s in enumerate(steps):
        t=ix+1;ip=s["ip"];d=s["delta"];pre=s["pre"];post=s["post"];op=s["op"]
        req(s["t"]==t and len(ip)==len(d)==2 and d!=[0,0],"tick or IP")
        req(type(pre)==type(post)==list and all(type(v)==int for v in pre+post),"stack schema")
        req(s["string"] is False,"string mode uncovered")
        if ix:
            a=steps[ix-1]
            req(a["next"]==ip and a["next_delta"]==d and a["post"]==pre,"STEP continuity")
        req(op==overlay.get(tuple(ip),cell(rows,tuple(ip))),"original source/overlay byte")
        if op==ord("p"):
            req(len(pre)>=3 and post==pre[:-3],"p semantics")
            xy=tuple(pre[-2:]);old=last.get(xy)
            w={"tick":t,"ip":ip,"cell":list(xy),"value":pre[-3],
               "previous_writer_tick":old["tick"] if old else None,
               "first_reader_tick":None,"overwritten_at_tick":None}
            if old:old["overwritten_at_tick"]=t
            writes.append(w);last[xy]=w;overlay[xy]=pre[-3]
        elif op==ord("g"):
            req(len(pre)>=2 and len(post)==len(pre)-1 and post[:-1]==pre[:-2],"g semantics")
            xy=tuple(pre[-2:]);old=last.get(xy)
            req(post[-1]==overlay.get(xy,cell(rows,xy)),"g last writer value")
            reads.append({"tick":t,"ip":ip,"cell":list(xy),"value":post[-1],
                          "owner_tick":old["tick"] if old else None,
                          "owner_ip":old["ip"] if old else None,
                          "owner_kind":"p" if old else "source"})
            if old and old["first_reader_tick"] is None:old["first_reader_tick"]=t
        elif op==ord("j"):
            n=pre[-1] if pre else 0
            req(post==(pre[:-1] if pre else []),"j stack")
            req(s["next"]==[ip[0]+(n+1)*d[0],ip[1]+(n+1)*d[1]],"j successor")
            gates.append((t,tuple(ip),n))
        elif op==ord("x"):
            req(len(pre)>=2 and post==pre[:-2],"x stack")
            req(s["next_delta"]==pre[-2:] and
                s["next"]==[ip[0]+pre[-2],ip[1]+pre[-1]],"x successor")
            xs.append((t,tuple(ip),tuple(s["next"])))
    req(steps[-1]["op"]==64 and steps[-1]["next"] is None,"HALT")
    req(len(route_audit(steps))==4 and len(xs)==11,"signed route")
    req((len(writes),len(reads),len(gates))==(9,12,6),"p/g/j counts")
    req(CROSS.issubset(set(xs)),"four route crossings")
    req(GATES.issubset(set(gates)),"three route gates")
    for tick,xy,writer,val in OWNERS:
        req(any(r["tick"]==tick and tuple(r["cell"])==xy and
                r["owner_tick"]==writer and r["value"]==val for r in reads),"g owner chain")
    req(not any(s["ip"]==[150,29] for s in steps),"unvisited x150")
    return {"schema":"qa31m-signed-last-owner-v1","source_blob":BLOB,
            "physical_steps_checked":2046,"p_count":9,"g_count":12,"j_count":6,"x_count":11,
            "crossings":[{"tick":t,"ip":xy,"next":n} for t,xy,n in sorted(CROSS)],
            "writes":writes,"reads":reads,
            "unknown":{"complete_arithmetic_stack_lineage":True,
                       "global_source_reachability":True,"all_inputs":True},
            "stage1_pass":False,"new_native_cases":0,
            "full_functional_qa_pass":False,"geometric_spaghetti_qa_pass":False}

def sabotage(steps,rows):
    attacks=[
      (1082,"pre",-3,2),(1229,"post",-1,0),(1349,"pre",-2,3),
      (1684,"pre",-3,0),(1779,"post",-1,0),(1254,"pre",-1,0),
      (1398,"next",0,120),(1301,"pre",-2,-200),(1445,"next",1,36),
      (1731,"next_delta",1,0),(1876,"op",None,48),(2046,"op",None,32)]
    n=0
    for t,k,i,v in attacks:
        changed=copy.deepcopy(steps)
        if i is None:changed[t-1][k]=v
        else:changed[t-1][k][i]=v
        try:check(changed,rows)
        except (AssertionError,KeyError,IndexError,TypeError,ValueError):n+=1
        else:raise AssertionError("mutation escaped at "+str(t))
    missing=copy.deepcopy(steps);missing.pop(1348)
    try:check(missing,rows)
    except (AssertionError,KeyError,IndexError,TypeError,ValueError):n+=1
    else:raise AssertionError("missing STEP accepted")
    altered=list(rows);x,y=steps[0]["ip"];r=bytearray(altered[y]);r[x]=64;altered[y]=bytes(r)
    try:check(steps,altered)
    except AssertionError:n+=1
    else:raise AssertionError("forged source accepted")
    req(n==14,"negative-control count")
    return n

def main():
    p=argparse.ArgumentParser()
    p.add_argument("source");p.add_argument("signed_actions_zip")
    p.add_argument("--out",default="qa31m_owner.json")
    a=p.parse_args();rows=source(a.source)
    steps=load_signed(Path(a.signed_actions_zip).read_bytes())
    report=check(steps,rows);report["hostile_rejected"]=sabotage(steps,rows)
    Path(a.out).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("QA31M_SOURCE_OWNER_PASS")
    print("QA31M_STEPS_2046_P_9_G_12_J_6_X_11")
    print("QA31M_HOSTILE_14_OF_14")
    print("QA31M_NO_NATIVE_NO_STAGE1_PASS")
if __name__=="__main__":main()
