#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native same-Program reset/overlapping scratch after '_' and w integration.

Reuse proven Native PyFunge two-live-Program/actual fault-at-p and explicit
Program constructor reset tests; swap only the exact source bytes of QA
underscore candidate. No Python calendar algorithm or production change.
"""
from __future__ import print_function
import hashlib
import json
import os
import stage1_native_concurrent_pg_fault_isolation as qualified

SOURCE="/underscore/underscore_w_candidate.b98"
EXPECTED="c0414e8dae9f933b5edb3405f7fc4e7f0684c04ce776acb541b9dd36c9810bbd"
def require(ok,msg):
    if not ok:raise AssertionError(msg)

code=open(SOURCE,"rb").read()
require(hashlib.sha256(code).hexdigest()==EXPECTED,
        "Native experimental underscore/w source SHA drift")
old=qualified.CODE.split("\n")
new=code.split("\n")
require(len(old)==len(new)==2016,"Native source 2D height changed")
for y,x in ((1334,986),(1334,1015),(1331,958),(1334,959)):
    require(old[y][x]==new[y][x],
            "Native actual j/p/g source cell changed "+repr((x,y)))
require(new[1334][951]=="_" and new[1332][951]=="w",
        "underscore and w source comparator placement changed")
qualified.CODE=code
qualified.main()
with open("/underscore/underscore_w_native_fault_reset.json","wb") as writer:
    writer.write(json.dumps({"schema":"befunge-stage1-native-underscore-w-fault-reset-v1",
        "scope":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
        "source_sha256":EXPECTED,"two_live_programs":True,
        "same_program_explicit_reset_cases":3,
        "native_fault_after_p_before_g":True,"result":"PASS"},indent=2)+"\n")
print("NATIVE_UNDERSCORE_W_PG_FAULT_RESET_PASS",
      "two_live_native_Programs",2,"same_Program_explicit_resets",3)
print("STAGE1_FINAL_SEMANTIC_STATE_OWNERSHIP=OPEN")
