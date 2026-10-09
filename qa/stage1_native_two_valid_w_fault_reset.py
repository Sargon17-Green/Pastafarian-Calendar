#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Test-only PyFunge two-live Program fault/explicit reset on two-valid-w code.

Reuse separately qualified real native p/g overlap and same-object reset.
No calendar logic in Python. This does not close state ownership globally.
"""
from __future__ import print_function
import hashlib
import json
import os
import stage1_native_concurrent_pg_fault_isolation as suite

SOURCE="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
BLOB="b6cf50de9ed45376db5fc4ebd003157210dff03b"
OUT="/validw"

def require(ok,msg):
    if not ok: raise AssertionError(msg)

with open(SOURCE,"rb") as stream: data=stream.read()
gitblob=hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()
require(gitblob==BLOB,"two-valid-w Native fault test source not SHA frozen")
before=suite.CODE.split("\n")
after=data.split("\n")
require(len(before)==len(after)==2016,"changed Funge-space dimensions")
for x,y in ((951,1335),(958,1331),(958,1325),(958,1324),
            (958,1321),(959,1334),(986,1334),(1015,1334),(1027,1334)):
    require(before[y][x]==after[y][x],
            "qualified Native p/g/j tested source byte changed "+repr((x,y)))
require(after[1332][951]=="w" and after[1331][951]=="_" and
        after[1336][951]=="]",
        "the expected actually executable Native branch opcodes changed")
suite.CODE=data
suite.main()
require(os.path.isdir(OUT),"Native two-valid-w trace output missing")
report={"schema":"befunge-stage1-two-valid-w-fault-reset-v1",
        "scope":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
        "source_git_blob":BLOB,"native_live_programs":2,
        "native_fault_between_p_and_g":True,
        "same_program_explicit_resets":3,"result":"PASS"}
with open(os.path.join(OUT,"two_valid_w_fault_reset.json"),"wb") as stream:
    stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("NATIVE_TWO_VALID_W_TWO_PROGRAMS_AND_SAME_OBJECT_FAULT_RESET_PASS")
print("STAGE1_FINAL_SEMANTIC_STATE_OWNERSHIP=OPEN")
