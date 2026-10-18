#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1 exact Native Year-5000 signed GATE INDEX origin (not day shift).

Python constructs transport and pre-enumerated expected index translation;
all 104 computations run unchanged independent test-only Befunge-98 source.
"""
from __future__ import print_function
import json,os,subprocess
SOURCE="reference/year5000_from_gates_rank.b98"
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
INDEX_ORIGINS=(0,-1,-7,-8,1,7,-((1<<129)+13),1<<129)
DAY_SHIFTS=(0,-((1<<130)+57))
RANKS_9=((1,(0,6)),(3,(2,8)),(6,(0,8)),(0,None),(7,None))
BAD_INDICES=((1,0),(2,0),(2,1),(3,3))
ROWS=[]
def sm(x):return [int(x<0),abs(x)]
def input_tokens(origin,shift,count,rank,malformed=None):
    f=sm(shift+100)
    f+=list(malformed) if malformed is not None else sm(origin)
    f.append(count)
    for i in range(count):f+=sm(shift+42*i)
    return f+[rank]
def run(label,origin,shift,count,rank,expected,malformed=None):
    values=input_tokens(origin,shift,count,rank,malformed)
    cmd=["timeout","--kill-after=5s","40s","pyfunge",
         "--disable-fprint","--no-concurrent","--no-filesystem",
         "-v98","-d2",SOURCE]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    out,err=p.communicate(" ".join(map(str,values))+"\n")
    if p.returncode:raise AssertionError("Native %s rc=%d err=%r"%
                                         (label,p.returncode,err[-300:]))
    got=list(map(int,out.split()))
    if got!=expected:raise AssertionError("%s: got=%r expected=%r"%
                                          (label,got,expected))
    ROWS.append({"case":label,"origin":origin,"shift":shift,"gate_count":count,
                 "rank":rank,"invalid_pair":list(malformed) if malformed else None,
                 "input":values,"expected":expected,"output":got,
                 "return_code":p.returncode})
    print("NATIVE_YEAR5000_SIGNED_GATE_INDEX_PASS",label)
def main():
    if not os.path.isdir("/year5000"):raise AssertionError("Native evidence directory missing")
    for shift in DAY_SHIFTS:
        for index in INDEX_ORIGINS:
            for rank,idx in RANKS_9:
                expected=([0,5000,index+idx[0],index+idx[1],
                          shift+42*idx[0],shift+42*idx[1]]
                          if idx is not None else [-1])
                run("nine_%s_%s_rank%d"%(index,shift,rank),
                    index,shift,9,rank,expected)
            run("seven_%s_%s_rank1"%(index,shift),index,shift,7,1,
                [0,5000,index,index+6,shift,shift+252])
        for pair in BAD_INDICES:
            run("invalid_index_sign_%s_%s_%s"%(shift,pair[0],pair[1]),
                0,shift,7,1,[-1],pair)
    if len(ROWS)!=104:
        raise AssertionError("invalid Native evidence count: %s"%len(ROWS))
    report={"schema":"befunge-stage1-year5000-signed-gate-index-v1",
            "source_git_blob":BLOB,"native_calls":len(ROWS),
            "scope":"SIGNED_GATE_INDEX_ORIGIN_NOT_JDN_STAGE1_OPEN",
            "functional_acceptance":False,"geometric_acceptance":False,
            "last_completed_stage":0,"records":ROWS}
    with open("/year5000/native_year5000_signed_gate_index.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_SIGNED_GATE_INDEX_104_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
