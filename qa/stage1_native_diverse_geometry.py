#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge 98 varied-input production geometry sampler (Python 2.7).

The sampler NEVER implements calendar arithmetic in Python. All valid seven
values come from three independent repository-native Befunge references.
It records actual PyFunge IP/p/g traces on varied inputs so the 2D route
proof is not based only on one good and one bad sample.

This is an evidence collection gate, NOT final spaghetti geometry acceptance.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys

COMMAND=["pyfunge","--disable-fprint","--no-concurrent",
         "--no-filesystem","-v98","-d2"]
SOURCE="src/interleaved_work_counts.b98"
REF_COUNTS="reference/work_counts.b98"
REF_SAVE="reference/save.b98"
OUTPUT="/diverse"
CASES=[
    ("zero_equal",       (0,0,0,0),True),
    ("foundation_cross", (1,15055672,1,15055670),True),
    ("forward_short",    (0,1,0,2),True),
    ("reverse_short",    (0,2,0,1),True),
    ("mixed_small",      (1,1,0,1),True),
    ("positive_negative",(0,123456789,1,987654321),True),
    ("negative_positive",(1,987654321,0,123456789),True),
    ("large_values",     (0,2**127,1,2**127-1),True),
    ("invalid_zero_sign",(1,0,0,0),False),
    ("invalid_big_sign", (2,10,0,10),False),
    # Additional native boundary and lexical-stress cases. Inputs are only
    # dispatched to native Befunge oracles; Python never computes a date.
    ("epoch_forward_one", (0,0,0,1),True),
    ("epoch_reverse_one", (0,1,0,0),True),
    ("recent_anchor_equal", (0,2461319,0,2461319),True),
    ("recent_anchor_next", (0,2461319,0,2461320),True),
    ("foundation_neighbor_forward", (1,15055671,1,15055670),True),
    ("foundation_neighbor_reverse", (1,15055670,1,15055671),True),
    ("invalid_target_zero_sign", (0,0,1,0),False),
    # Raw negative lexemes are scanner-only cases: they halt *before* the
    # arithmetic handoff, so their Native IP graph cannot enter this corpus.
]
def check(ok,why):
    if not ok:
        raise AssertionError(why)

def native(path,stdin,trace=None):
    env=os.environ.copy()
    env.pop("BF98_TRACE_LOG",None)
    if trace:
        env["BF98_TRACE_LOG"]=trace
        env["PYTHONPATH"]="/work/qa"
    cmd=["timeout","--kill-after=2s","50s"]+COMMAND+[path]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
    out,err=p.communicate(stdin)
    check(p.returncode==0,
          "NATIVE_DIVERSE_PROCESS_FAILED %s input=%r exit=%d stderr=%r" %
          (path,stdin,p.returncode,err[-700:]))
    return out.split()

def expected_for(sign_c,mag_c,sign_t,mag_t):
    day="%s %s %s %s\n"%(sign_c,mag_c,sign_t,mag_t)
    result=(native(REF_COUNTS,day)+
            native(REF_SAVE,"%s %s\n"%(sign_c,mag_c))+
            native(REF_SAVE,"%s %s\n"%(sign_t,mag_t)))
    check(len(result)==7,"native Befunge references returned wrong shape")
    return result

def main():
    check(os.path.isdir(OUTPUT),"expected writable native /diverse artifact volume")
    records=[]
    for label,fields,isvalid in CASES:
        stdin=" ".join(map(str,fields))+"\n"
        trace_path=os.path.join(OUTPUT,label+".tsv")
        got=native(SOURCE,stdin,trace=trace_path)
        want=expected_for(*fields) if isvalid else ["-1"]*7
        check(got==want,"native oracle differential %s %r vs %r" %
              (label,got,want))
        check(os.path.isfile(trace_path) and os.path.getsize(trace_path)>50000,
              "missing measured trace for "+label)
        with open(os.path.join(OUTPUT,label+".out"),"wb") as stream:
            stream.write(" ".join(got)+"\n")
        digest=hashlib.sha256()
        with open(trace_path,"rb") as stream:
            while True:
                chunk=stream.read(1<<18)
                if not chunk:break
                digest.update(chunk)
        records.append({"case":label,"fields":list(fields),"valid":isvalid,
                        "trace_file":label+".tsv",
                        "trace_sha256":digest.hexdigest(),
                        "output":got})
        print("NATIVE_DIVERSE_PRODUCTION_TRACE_PASS",label,
              "input",repr(stdin.strip()),"output_fields",len(got))
        sys.stdout.flush()
    with open(os.path.join(OUTPUT,"diverse_manifest.json"),"wb") as stream:
        stream.write(json.dumps({"schema":"befunge-stage1-diverse-native-v1",
                                 "cases":records},sort_keys=True,indent=2)+"\n")
    print("NATIVE_DIVERSE_PRODUCTION_ORACLE_AND_TRACE_PASS",len(CASES),
          "cases","valid",sum(t[2] for t in CASES),
          "invalid",sum(not t[2] for t in CASES))
if __name__=="__main__":main()
