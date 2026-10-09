#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Reuse previously qualified Native p/g fault-reset tests on NEW QA candidate.

No calendar code in Python. Existing Native Program object/fault and
independent Befunge reference tests run against the exact new source blob.
"""
from __future__ import print_function
import hashlib
import stage1_native_concurrent_pg_fault_isolation as native

SOURCE="qa/interleaved_work_counts_reflective_crossing_candidate.b98"

def blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

with open(SOURCE,"rb") as stream:
    new_code=stream.read()
if blob(new_code)!="8f2cf8afef61818244747582fe7c20a74ee18943":
    raise AssertionError("candidate source changed during reset proof")
old=native.CODE.split("\n")
new=new_code.split("\n")
for y,x in ((1334,986),(1334,1015),(1331,958),(1334,959)):
    if old[y][x]!=new[y][x]:
        raise AssertionError("reset test p/g/j route source coordinate drift")
# The original Native test owns all Program setup, explicit reset and live
# fault scheduling. Only its Befunge source bytes are substituted.
native.CODE=new_code
native.main()
print("NATIVE_REFLECTIVE_CANDIDATE_PG_FAULT_RESET_PASS")
print("STAGE1_FINAL_SEMANTIC_STATE_OWNERSHIP=OPEN")
