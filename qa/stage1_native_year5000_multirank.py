#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1 Year-5000 Native ranked-candidate/tie/boundary geometry.
The normative six-field answers come solely from the native Befunge
reference/year5000_from_gates_rank.b98 executable. Python transports inputs,
asserts finite hand-enumerated structural witnesses and records evidence.
It does not implement Pastafarian Sauce or calendar computations.
"""
from __future__ import print_function
import json,os,subprocess
SOURCE="reference/year5000_from_gates_rank.b98"
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
SHIFTS=(0,1,123456789,-1,-84,-253,-((1<<127)+19),1<<128)
BOUNDARY_SHIFTS=(0,-253)
OUTSIDE_SHIFTS=(0,-253,1<<128)
PAIRS=((0,6),(1,7),(2,8),(0,7),(1,8),(0,8))
AT_OPEN=((0,6),(1,7),(0,7),(1,8),(0,8))
RECORDS=[]

def pair(v):return [int(v<0),abs(v)]
def fields(shift,offset,rank):
    data=pair(shift+offset)+[0,0,9]
    for index in range(9):data+=pair(shift+42*index)
    return data+[rank]
def run(label,shift,offset,rank,candidate):
    f=fields(shift,offset,rank)
    expected=(list(candidate) if candidate is not None else [-1])
    cmd=["timeout","--kill-after=4s","40s","pyfunge","--disable-fprint",
         "--no-concurrent","--no-filesystem","-v98","-d2",SOURCE]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    out,err=p.communicate(" ".join(map(str,f))+"\n")
    if p.returncode:
        raise AssertionError("Native rank case %s rc=%d stderr=%r"%
                             (label,p.returncode,err[-500:]))
    actual=[int(x) for x in out.split()]
    if actual!=expected:
        raise AssertionError("Native rank mismatch %s: %r != %r"%
                             (label,actual,expected))
    RECORDS.append({"case":label,"shift":shift,"offset":offset,
                    "rank":rank,"input":f,"expected":expected,"output":actual,
                    "return_code":p.returncode})
    print("NATIVE_YEAR5000_RANKED_TIE_BOUNDARY_PASS",label)
def witness(shift,indices):
    i,j=indices
    return [0,5000,i,j,shift+42*i,shift+42*j]
def main():
    if not os.path.isdir("/year5000"):
        raise AssertionError("Native Year-5000 evidence mount missing")
    # Six candidate ranks: three 252-day ties, two 294-day ties,
    # then one 336-day candidate. Sorting is length, then opening index.
    for s in SHIFTS:
        for n,indices in enumerate(PAIRS,1):
            run("rank_%s_%d"%(s,n),s,100,n,witness(s,indices))
        for bad in (0,7):
            run("invalid_rank_%s_%d"%(s,bad),s,100,bad,None)
    # At the third gate (day 84) the pair opening at gate 2 is forbidden:
    # opening boundary is strict. Five choices remain.
    for s in BOUNDARY_SHIFTS:
        for n,indices in enumerate(AT_OPEN,1):
            run("strict_open_%s_%d"%(s,n),s,84,n,witness(s,indices))
        run("strict_open_%s_6"%s,s,84,6,None)
    # Outside all candidate-year intervals, even an otherwise legal rank fails.
    for s in OUTSIDE_SHIFTS:
        for offset in (0,337):
            run("outside_%s_%d"%(s,offset),s,offset,1,None)
    total=len(SHIFTS)*8+len(BOUNDARY_SHIFTS)*6+len(OUTSIDE_SHIFTS)*2
    if len(RECORDS)!=total:raise AssertionError("rank evidence missing")
    report={"schema":"befunge-stage1-native-year5000-multirank-v1",
            "source_git_blob":BLOB,
            "scope":"NATIVE_RANK_TIES_SIGNED_AXIS_FINITE_STAGE1_OPEN",
            "native_invocations":total,"records":RECORDS,
            "functional_acceptance":False,"geometric_acceptance":False,
            "last_completed_stage":0}
    with open("/year5000/native_year5000_multirank.json","wb") as output:
        output.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_MULTIRANK_TIE_ORDER_AND_OPEN_BOUNDARY_PASS",
          total,"NATIVE_INVOCATIONS","STAGE1_FINAL_ACCEPTANCE=NO")
if __name__=="__main__":main()
