#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 native Befunge reference-state ownership: independent live programs.

Reference domains: bounded-composition count/unrank, weaving count/unrank,
Year-5000 selection at two translated input vectors. 6 native CLI baselines,
12 native live pairs, 24 real Program executions. Never implements calendar
arithmetic in Python; the reference .b98 programs execute all calculations.
A finite reference-only ownership check, NOT production semantic acceptance.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.exception import IPStopped, IPQuitted

CASES = (
    ("bc", "reference/count_bounded_compositions.b98",
     "5 2 1 4\n", "90c0c45205cc6efca418367f02b6ee3116bcb2d7"),
    ("bu", "reference/unrank_bounded_composition.b98",
     "5 2 1 4 1\n", "f6ebb3980d3eecb4e159e42b2a01499323257dc6"),
    ("wc", "reference/count_weavings.b98",
     "3 3 3 2\n", "d57ef8da12e7cae7e62153407214f9f903eca280"),
    ("wu", "reference/unrank_weaving.b98",
     "3 3 3 2 1\n", "a48359619ab5391b156e6eefdd6d36a5e500611a"),
    ("y0", "reference/year5000_from_gates_rank.b98",
     "0 100 0 0 7 0 0 0 42 0 84 0 126 0 168 0 210 0 252 1\n",
     "c70f15354979aafdd0ea0c83045ef2a54dd996f9"),
    ("y1", "reference/year5000_from_gates_rank.b98",
     "0 1100 0 0 7 0 1000 0 1042 0 1084 0 1126 0 1168 0 1210 0 1252 1\n",
     "c70f15354979aafdd0ea0c83045ef2a54dd996f9"),
)
PAIRS = (("bc","wc"),("bu","wu"),("y0","wc"),
         ("y1","bu"),("y0","y1"),("bc","bu"))
SCHEDULES = (("AB_1_1",1,1,False),("BA_3_7",3,7,True))
OUT = "/refowner/native_reference_live_ownership.json"
MAX_TICKS = 1000000  # bounded native interleave; prior 180000 truncated actual first reference pair
GUARDS = ((0,0),(1,0),(8,0),(0,20),(4,20),(8,20),
          (0,30),(0,40),(0,50),(1,50),(0,300),(0,352))

def need(ok, msg):
    if not ok:
        raise AssertionError(msg)

def git_blob(data):
    return hashlib.sha1("blob %d\0%s" % (len(data),data)).hexdigest()

def expected_cli(path, raw):
    cmd = ["timeout","--kill-after=2s","60s","pyfunge",
           "--disable-fprint","--no-concurrent","--no-filesystem",
           "-v98","-d2",path]
    process = subprocess.Popen(cmd,stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=process.communicate(raw)
    need(process.returncode==0,"Native reference CLI failed: "+path+repr(err[-450:]))
    return out.split()

def make(source, raw):
    inp=StringIO.StringIO(raw)
    output=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=inp,stdout=output)
    program=Program(Befunge98,platform=platform)
    program.load_code(source)
    program.create_ip()
    need(len(program.ips)==1,"Native reference did not start one IP")
    return {"program":program,"input":inp,"output":output,
            "point":program.ips[0].position.__class__,"steps":0}

def snapshot(item):
    p=item["program"]
    ips=tuple((tuple(ip.position),tuple(ip.delta),tuple(ip.offset),
               bool(ip.stringmode),
               tuple(tuple(str(z) for z in frame) for frame in ip.stack))
              for ip in p.ips)
    mem=tuple(int(p.space.get(item["point"](xy))) for xy in GUARDS)
    return (ips,mem,tuple(p.space.boundmin),tuple(p.space.boundmax),
            item["input"].tell(),item["output"].tell())

def tick(item):
    program=item["program"]
    if not program.ips: return
    need(len(program.ips)==1,"unexpected concurrent native reference IPs")
    ip=program.ips[0]
    try:
        program.execute_step()
    except IPStopped:
        program.remove_ip(ip)
    except IPQuitted:
        for other_ip in list(program.ips):
            program.remove_ip(other_ip)
    item["steps"]+=1
    need(item["steps"]<=MAX_TICKS,"Native reference step budget exceeded")

def run_pair(cases,reference,left,right,schedule):
    name,qa,qb,reverse=schedule
    pa,ra=cases[left]
    pb,rb=cases[right]
    a=make(pa,ra)
    b=make(pb,rb)
    need(a["program"].space is not b["program"].space and
         a["program"].semantics is not b["program"].semantics and
         a["input"] is not b["input"] and a["output"] is not b["output"],
         "Native reference Programs share state before execution")
    cls=type(a["program"].space)
    need(cls is type(b["program"].space),
         "PyFunge native reference Space types differ")
    get0,put0,putspace0=cls.get,cls.put,cls.putspace
    current=[None]
    metrics={"a":{"get":0,"put":0,"putspace":0},
             "b":{"get":0,"put":0,"putspace":0}}
    def read(self,*args,**kwargs):
        if current[0]:
            key,item=current[0]
            need(self is item["program"].space,
                 "reference got another Program's memory")
            metrics[key]["get"]+=1
        return get0(self,*args,**kwargs)
    def write(self,*args,**kwargs):
        need(current[0] is not None,
             "Native reference wrote memory outside active quantum")
        key,item=current[0]
        need(self is item["program"].space and len(args)>=2,
             "reference wrote peer Program memory")
        result=put0(self,*args,**kwargs)
        need(int(get0(self,args[0]))==int(args[1]),
             "reference stored value did not match put operand")
        metrics[key]["put"]+=1
        return result
    def writespace(self,*args,**kwargs):
        need(current[0] is not None,
             "Native reference putspace called with no current Program")
        key,item=current[0]
        need(self is item["program"].space,
             "Native reference putspace escaped owned Funge-space")
        metrics[key]["putspace"]+=1
        return putspace0(self,*args,**kwargs)
    print("NATIVE_REFERENCE_LIVE_PAIR_BEGIN",name,left,right,"budget",MAX_TICKS)
    sys.stdout.flush()
    order=(("a",a,qa),("b",b,qb))
    if reverse: order=order[::-1]
    overlap=0
    checked=0
    rounds=0
    try:
        cls.get,cls.put,cls.putspace=read,write,writespace
        while a["program"].ips or b["program"].ips:
            rounds+=1
            need(rounds<=MAX_TICKS,"Native reference pair exceeded bound "+name+" "+left+"/"+right+" rounds="+str(rounds)+" ticks="+str((a["steps"],b["steps"]))+" still_live="+str((bool(a["program"].ips),bool(b["program"].ips))))
            if a["program"].ips and b["program"].ips:overlap+=1
            for key,item,quantum in order:
                peer=b if key=="a" else a
                if not item["program"].ips:continue
                before=snapshot(peer)
                for unused in range(quantum):
                    if not item["program"].ips:break
                    current[0]=(key,item)
                    try:tick(item)
                    finally:current[0]=None
                need(before==snapshot(peer),
                     "one Native reference quantum mutated peer state")
                checked+=1
    finally:
        current[0]=None
        cls.get,cls.put,cls.putspace=get0,put0,putspace0
    output_a=a["output"].getvalue().split()
    output_b=b["output"].getvalue().split()
    need(output_a==reference[left] and output_b==reference[right],
         "concurrent references differ from independent native CLI")
    need(overlap>0 and checked>=2,
         "Native reference Programs not genuinely interleaved")
    for key in ("a","b"):
        need(metrics[key]["get"]>0 and metrics[key]["putspace"]==0,
             "reference missing Native read provenance or unexpected putspace")
    return {"left":left,"right":right,"schedule":name,
            "left_output":output_a,"right_output":output_b,
            "left_steps":a["steps"],"right_steps":b["steps"],
            "left_get":metrics["a"]["get"],"right_get":metrics["b"]["get"],
            "left_put":metrics["a"]["put"],"right_put":metrics["b"]["put"],
            "left_putspace":metrics["a"]["putspace"],
            "right_putspace":metrics["b"]["putspace"],
            "overlap_rounds":overlap,"peer_state_checks":checked,
            "separate_programs_and_spaces":True,"all_space_apis_owned":True,
            "outputs_reference_equal":True,"terminated":True}

def main():
    need(os.path.isdir("/refowner"),"Native reference evidence mount missing")
    files={}
    expected={}
    sources={}
    for label,path,raw,pin in CASES:
        source=open(path,"rb").read()
        need(git_blob(source)==pin,"pinned reference Befunge drift: "+label)
        sources[path]=source
        files[label]=(source,raw)
        expected[label]=expected_cli(path,raw)
        need(len(expected[label])>=1,
             "Native reference output empty: "+label)
    need(expected["bc"]==["4"] and expected["wc"]==["26"] and
         expected["y0"]==["0","5000","0","6","0","252"] and
         expected["y1"]==["0","5000","0","6","1000","1252"],
         "known Stage-1 structural/Year5000 witnesses changed")
    signatures={}
    records=[]
    for sched in SCHEDULES:
        for left,right in PAIRS:
            row=run_pair(files,expected,left,right,sched)
            for label,side in ((left,"left"),(right,"right")):
                sig=(row[side+"_steps"],row[side+"_get"],
                     row[side+"_put"],tuple(row[side+"_output"]))
                if label in signatures:
                    need(sig==signatures[label],
                         "Native reference depended on peer or step schedule")
                else:signatures[label]=sig
            records.append(row)
            print("NATIVE_REFERENCE_LIVE_OWNER_PASS",sched[0],left,right,
                  "ticks",row["left_steps"],row["right_steps"])
            sys.stdout.flush()
    need(len(records)==12 and len(signatures)==6,
         "Native reference case/schedule corpus incomplete")
    report={"schema":"befunge-stage1-native-reference-live-owner-v1",
            "status":"QA_ONLY_STAGE1_OPEN","pairs":12,"programs":24,
            "native_cli_baselines":6,"profiles":[s[0] for s in SCHEDULES],
            "source_blobs":dict((path,git_blob(content))
                                for path,content in sources.items()),
            "expected_by_label":expected,
            "records":records,"stage1_final_acceptance":False}
    with open(OUT,"wb") as fh:
        fh.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_REFERENCE_LIVE_OWNER_12_PAIRS_PASS")
    print("STAGE1_REFERENCE_AND_PRODUCTION_FINAL_GATES_OPEN")

if __name__=="__main__":
    main()
