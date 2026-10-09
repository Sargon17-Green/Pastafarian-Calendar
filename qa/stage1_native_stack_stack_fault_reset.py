#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native two-live Program and same-object fault/reset on { 3u } arithmetic.

The previously qualified independent native PyFunge test owns Program
creation, overlapping p/g memory operations, scheduling/fault injection,
input-to-output checks and same-Program explicit resets. Only exact SHA
pinned experimental Befunge source bytes are substituted. No calendar
arithmetic, output oracle or Stage-2 code is implemented in Python.
"""
from __future__ import print_function
import hashlib
import json
import os
import stage1_native_concurrent_pg_fault_isolation as qualified

SOURCE="/stack/stack_stack_candidate.b98"
EXPECTED="3e64ba67eaaaf684fef221be33c368527a50a3c986e9f0b63e73ef81b21cdb59"
OUT="/stack"

def require(ok,msg):
    if not ok:raise AssertionError(msg)

require(os.path.isdir(OUT),"native stack-stack evidence volume missing")
code=open(SOURCE,"rb").read()
require(hashlib.sha256(code).hexdigest()==EXPECTED,
        "Native stack-stack exact source changed before injected fault")
previous=qualified.CODE.split("\n")
candidate=code.split("\n")
require(len(previous)==len(candidate)==2016,
        "experimental native source height changed")
for x,y in ((951,1335),(958,1331),(958,1325),(958,1324),
            (958,1321),(959,1334),(986,1334),(1015,1334),(1027,1334)):
    require(previous[y][x]==candidate[y][x],
            "tested Native arithmetic j/p/g source byte changed "+repr((x,y)))
require(candidate[1330][954]=="{" and
        candidate[1328][954]=="u" and
        candidate[1322][954]=="}" and
        candidate[1332][955]==">",
        "real Native stack-stack arithmetic instruction missing")
qualified.CODE=code
qualified.main()
report={"schema":"befunge-stage1-native-stack-stack-fault-reset-v1",
        "status":"QA_ONLY_NOT_STAGE1_ACCEPTANCE",
        "native_source_sha256":EXPECTED,
        "two_live_native_programs":True,
        "fault_after_p_before_g":True,
        "same_program_explicit_resets":3,
        "result":"PASS"}
with open(os.path.join(OUT,"stack_stack_native_fault_reset.json"),"wb") as stream:
    stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("NATIVE_STACK_STACK_OVERLAPPING_PG_FAULT_AND_EXPLICIT_RESET_PASS",
      "two_live_programs",2,"same_Program_resets",3)
print("STAGE1_FINAL_SEMANTIC_STATE_OWNERSHIP=OPEN")
