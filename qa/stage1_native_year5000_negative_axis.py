#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1: Native Befunge Year-5000 signed/negative gate-coordinate evidence.
Python only supplies canonical sign/magnitude inputs and compares outputs.
The calendar is computed by reference/year5000_from_gates_rank.b98.
Finite corpus only; Stage 1 remains open.
"""
from __future__ import print_function
import json, os, subprocess
SHIFTS=(-1,-21,-84,-252,-253,-1000,-123456789,
        -((1<<127)+19),-(10**100+123))
INNER=(1,100,252)
OUTER=(0,253)
RANKS=(0,2)
SOURCE="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
ROWS=[]
def pair(n):
    return [int(n<0),abs(n)]
def fields(shift,offset,rank):
    # The second pair is the initial GATE INDEX 0, not a calendar day.
    f=pair(shift+offset)+[0,0,7]
    for i in range(7): f+=pair(shift+42*i)
    return f+[rank]
def native(label,f,want):
    cmd=["timeout","--kill-after=5s","35s","pyfunge","--disable-fprint",
         "--no-concurrent","--no-filesystem","-v98","-d2",
         "reference/year5000_from_gates_rank.b98"]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    out,err=p.communicate(" ".join(map(str,f))+"\n")
    if p.returncode:
        raise AssertionError("Native %s rc=%d stderr=%r"%(label,p.returncode,err[-500:]))
    got=[int(x) for x in out.split()]
    if got!=list(want):
        raise AssertionError("Native %s got=%r want=%r"%(label,got,want))
    ROWS.append({"case":label,"input":f,"output":got,
                 "expected":list(want),"return_code":p.returncode})
    print("NATIVE_YEAR5000_SIGNED_AXIS_PASS",label)
def main():
    if not os.path.isdir("/year5000"):raise AssertionError("evidence volume missing")
    for o in INNER:native("anchor_%d"%o,fields(0,o,1),[0,5000,0,6,0,252])
    for s in SHIFTS:
        for o in INNER:
            native("inside_%s_%d"%(s,o),fields(s,o,1),
                   [0,5000,0,6,s,s+252])
        for o in OUTER:
            native("outside_%s_%d"%(s,o),fields(s,o,1),[-1])
        for rank in RANKS:
            native("bad_rank_%s_%d"%(s,rank),fields(s,100,rank),[-1])
    total=len(INNER)+len(SHIFTS)*(len(INNER)+len(OUTER)+len(RANKS))
    if len(ROWS)!=total:raise AssertionError("Native records missing")
    report={"schema":"befunge-stage1-native-year5000-negative-axis-v1",
            "source_git_blob":SOURCE,"native_invocations":total,
            "shift_values":list(SHIFTS),"records":ROWS,
            "scope":"NEGATIVE_SIGNED_AXIS_FINITE_NATIVE_CORPUS_STAGE1_OPEN",
            "functional_acceptance":False,"geometric_acceptance":False,
            "last_completed_stage":0}
    with open("/year5000/native_year5000_negative_axis.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_NEGATIVE_SIGNED_AXIS_PASS",total,
          "NATIVE_CALLS; STAGE1_FINAL_ACCEPTANCE=NO")
if __name__=="__main__":main()
