#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Two live Native Programs + injected p/g fault + explicit same-Program reset.

Runs existing reference-qualified PyFunge fault suite on exact frozen
Native two-valid-branch source. Does NOT use Python date arithmetic.
"""
from __future__ import print_function
import hashlib
import json
import os
import stage1_native_concurrent_pg_fault_isolation as qualified
SOURCE="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
EXPECTED="b6cf50de9ed45376db5fc4ebd003157210dff03b"
data=open(SOURCE,"rb").read()
sha=hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()
if sha!=EXPECTED:raise AssertionError("Native two-valid w source Git blob drift")
old=qualified.CODE.split("\n");new=data.split("\n")
if len(old)!=len(new) or len(new)!=2016:raise AssertionError("bad Native source shape")
for x,y in ((986,1334),(1015,1334),(958,1331),(959,1334),(958,1324)):
    if old[y][x]!=new[y][x]:
        raise AssertionError("Native actual arithmetic j/p/g/reflective cell changed")
if new[1332][951]!="w" or new[1331][951]!="_":
    raise AssertionError("Native selected w/_ corridor absent")
qualified.CODE=data
qualified.main()
with open("/validw/native_two_valid_w_fault_reset.json","wb") as f:
    f.write(json.dumps({"schema":"stage1-native-two-valid-w-fault-reset-v1",
         "scope":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
         "candidate_blob":EXPECTED,"two_live_programs":2,
         "same_program_explicit_reset_cases":3,"result":"PASS"},sort_keys=True,indent=2)+"\n")
print("NATIVE_TWO_VALID_W_PG_FAULT_RESET_PASS",EXPECTED)
print("STAGE1_FINAL_SEMANTIC_STATE_OWNERSHIP=OPEN")
