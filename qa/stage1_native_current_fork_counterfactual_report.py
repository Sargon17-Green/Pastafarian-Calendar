#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Current-source Native opposite-| experiment: evidence not waived.

The old source's four-case strict causal PASS is checked separately
on its frozen SHA. This script runs the promoted w/_ production on real
PyFunge Program instances, reports inert upstream mutations as OPEN.
Python never implements calendar arithmetic.
"""
from __future__ import print_function
import hashlib
import sys
import stage1_native_fork_counterfactual as old
import stage1_native_diverse_geometry as suite

SRC="src/interleaved_work_counts.b98"
EXPECT="b6cf50de9ed45376db5fc4ebd003157210dff03b"
data=open(SRC,"rb").read()
def need(x,s):
    if not x:raise AssertionError(s)
need(hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()==EXPECT,
     "current QA production bytes not pinned")
old.CODE=data
cases=dict((name,(fields,valid)) for name,fields,valid in suite.CASES)
inert=[]
for name in old.CASES:
    values,valid=cases[name]
    need(valid,"Native fork controls must target valid input")
    raw=" ".join(map(str,values))+"\n"
    ref=suite.expected_for(*values)
    base=suite.native(SRC,raw)
    sham=old.run_native(raw,False)
    mutant=old.run_native(raw,True)
    need(base==ref and sham["stdout"]==ref and
         sham["exit_status"]=="normal" and sham["live_ips"]==0,
         "new QA production Native control fails independent Befunge reference "+name)
    need(len(sham["gate_observations"])==1 and
         len(mutant["gate_observations"])>=1 and
         mutant["gate_observations"][0][1]==1-sham["gate_observations"][0][0],
         "actual Native opposite operand was not applied "+name)
    effect=(mutant["exit_status"]!="normal" or
            mutant["stdout"]!=ref or mutant["live_ips"]!=0)
    if not effect:inert.append(name)
    print("NATIVE_CURRENT_UPSTREAM_FORK_CAUSALITY_MEASURED",
          name,"observable_effect",effect)
    sys.stdout.flush()
print("NATIVE_CURRENT_UPSTREAM_FORK_CAUSALITY_GAP",
      "OPEN" if inert else "NOT_OBSERVED_IN_THESE_CASES",
      "inert_valid_inputs",repr(inert))
print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; historical strict PASS cannot imply new-source causality")
