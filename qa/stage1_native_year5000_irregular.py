#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1: finite native Befunge Year-5000 irregular-gate witnesses.
Python marshals signed inputs and compares hand-enumerated index pairs; it
does not calculate calendar outputs from a non-Befunge implementation.
"""
from __future__ import print_function
import json,os,subprocess
PIN="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
BIG=(1<<130)+57
SHIFTS=(0,-BIG,BIG)
# All consecutive gate gaps are in the normative range 42..963.
# Explicit rank order tests length-before-opening, 252 and 5778 limits.
GROUPS=(
 ("cross",(0,60,130,210,280,340,550,605,690),150,
  ((1,7),(0,6),(2,8),(0,7),(1,8),(0,8)),
  ((1,7),(0,6),(0,7),(1,8),(0,8)),
  ((1,7),(2,8),(0,7),(1,8),(0,8))),
 ("floor",(0,42,84,126,168,210,252,302,362),100,
  ((0,6),(1,7),(2,8),(0,7),(1,8),(0,8)),
  ((0,6),(1,7),(0,7),(1,8),(0,8)),
  ((1,7),(2,8),(0,7),(1,8),(0,8))),
 ("ceiling",(0,963,1926,2889,3852,4815,5778,5848,5948),2300,
  ((2,8),(1,7),(1,8),(0,6)),
  ((1,7),(1,8),(0,6)),
  ((2,8),(1,7),(1,8))),
)
ROWS=[]
FAMILY_SCOPE=os.environ.get("YEAR5000_FAMILY","all")
FAMILY_COUNTS={"cross":81,"floor":81,"ceiling":57,"all":219}
def sm(n):return [int(n<0),abs(n)]
def fields(g,s,day,rank):
    tokens=sm(s+day)+[0,0,9] # gate INDEX zero, not a second day
    for value in g:tokens+=sm(s+value)
    return tokens+[rank]
def native(label,family,s,mode,day,rank,gates,expected):
    values=fields(gates,s,day,rank)
    command=["timeout","--kill-after=5s","45s","pyfunge",
             "--disable-fprint","--no-concurrent","--no-filesystem",
             "-v98","-d2","reference/year5000_from_gates_rank.b98"]
    p=subprocess.Popen(command,stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(" ".join(map(str,values))+"\n")
    if p.returncode:raise AssertionError("Native %s rc=%s err=%r"%
                                           (label,p.returncode,err[-500:]))
    got=list(map(int,out.split()))
    if got!=expected:raise AssertionError("%s: got=%r want=%r"%
                                          (label,got,expected))
    ROWS.append({"case":label,"family":family,"shift":s,"mode":mode,
                 "day_offset":day,"rank":rank,"input_fields":values,
                 "expected":expected,"output":got,"return_code":p.returncode})
    print("NATIVE_IRREGULAR_YEAR5000_PASS",label)
def main():
    if not os.path.isdir("/year5000"):raise AssertionError("evidence mount absent")
    if FAMILY_SCOPE not in FAMILY_COUNTS:
        raise AssertionError("unknown YEAR5000_FAMILY shard")
    for family,gates,interior,full,opened,after in GROUPS:
        if FAMILY_SCOPE!="all" and family!=FAMILY_SCOPE:continue
        if len(gates)!=9 or any(not 42<=gates[i+1]-gates[i]<=963
                                for i in range(8)):
            raise AssertionError("invalid synthetic gate gaps")
        for s in SHIFTS:
            for mode,day,ranks in (
                ("interior",interior,full),
                ("strict_open",gates[2],opened),
                ("after_close",gates[6]+1,after),
                ("closed_end",gates[6],full)):
                for rank,(i,j) in enumerate(ranks,1):
                    label="%s_%s_%s_%d"%(family,s,mode,rank)
                    native(label,family,s,mode,day,rank,gates,
                           [0,5000,i,j,s+gates[i],s+gates[j]])
                rank=len(ranks)+1
                native("%s_%s_%s_overflow"%(family,s,mode),
                       family,s,mode,day,rank,gates,[-1])
                if mode=="interior":
                    native("%s_%s_zero_rank"%(family,s),family,s,mode,
                           day,0,gates,[-1])
    if len(ROWS)!=FAMILY_COUNTS[FAMILY_SCOPE]:
        raise AssertionError("missing Native %s records: %d"%
                             (FAMILY_SCOPE,len(ROWS)))
    result={"schema":"befunge-stage1-year5000-irregular-native-v1",
            "source_git_blob":PIN,"native_invocations":len(ROWS),
            "family_scope":FAMILY_SCOPE,
            "scope":"IRREGULAR_GATES_AND_EXACT_5778_LIMIT_STAGE1_OPEN",
            "functional_acceptance":False,"geometric_acceptance":False,
            "last_completed_stage":0,"records":ROWS}
    with open("/year5000/native_year5000_irregular.json","wb") as f:
        f.write(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_IRREGULAR_%s_%d_CASES_PASS_STAGE1_OPEN"%
          (FAMILY_SCOPE,len(ROWS)))
if __name__=="__main__":main()
