#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native overlapping p/g, fault and SAME-Program reset for test-only w.

The independent native-qualified suite owns Program creation, two live
instances, actual shared-coordinate Funge p/g writes, injected faults,
explicit reset and reference parity. Only frozen Befunge source is swapped.
No Python calendar arithmetic or Stage-1 acceptance is performed.
"""
from __future__ import print_function
import hashlib
import json
import os
import stage1_native_concurrent_pg_fault_isolation as qualified

SOURCE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
FROZEN_GIT_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
OUT="/wturn"

def require(ok,msg):
    if not ok:raise AssertionError(msg)

with open(SOURCE,"rb") as f:
    candidate=f.read()
git_sha=hashlib.sha1("blob %d\0%s"%(len(candidate),candidate)).hexdigest()
require(git_sha==FROZEN_GIT_BLOB,"Native w source bytes not frozen")
old=qualified.CODE.split("\n")
new=candidate.split("\n")
require(len(old)==len(new)==2016,"Native w geometry height changed")
for x,y in ((951,1335),(958,1331),(958,1325),(958,1324),
            (958,1321),(959,1334),(986,1334),(1015,1334),(1027,1334)):
    require(old[y][x]==new[y][x],
            "Native fork j/p/g integration geometry changed "+str((x,y)))
require(new[1332][951]=="w","Native comparator missing from frozen candidate")
qualified.CODE=candidate
qualified.main()
require(os.path.isdir(OUT),"Native evidence mount missing")
report={"schema":"befunge-stage1-native-w-pg-reset-v1",
        "scope":"QA_ONLY_TEST_SOURCE_NOT_STAGE1_ACCEPTANCE",
        "candidate_git_blob":FROZEN_GIT_BLOB,
        "overlapping_native_programs":2,
        "same_program_explicit_resets":3,
        "result":"PASS"}
with open(os.path.join(OUT,"w_candidate_pg_fault_reset.json"),"wb") as f:
    f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("NATIVE_W_CANDIDATE_PG_FAULT_AND_SAME_PROGRAM_RESET_PASS",FROZEN_GIT_BLOB)
print("FUNCTIONAL_QA_PASS=NO GEOMETRIC_SPAGHETTI_QA_PASS=NO")
