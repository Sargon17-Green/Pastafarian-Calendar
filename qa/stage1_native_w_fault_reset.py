#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native same-Program p/g fault-reset audit on the unpromoted w candidate.

Re-run the established *actual PyFunge* two-live-Program overlapping-scratch
and interrupted-after-p experiment, including explicit SAME Program object
constructor reset, using the EXACT frozen w source. No Python calendar code,
no fallback interpreter and no modification to QA production or canonical.
"""
from __future__ import print_function
import hashlib
import os
import stage1_native_concurrent_pg_fault_isolation as native

FROZEN="qa/interleaved_work_counts_w_data_branch_candidate.b98"
EXECUTED="/wturn/w_data_branch_candidate.b98"
EXPECTED_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
EXPECTED_SHA256="9b1fb027286ca8bf881d9edcd97385843760fc0be48eb83d4c08d1a84c3d739e"

def require(ok,message):
    if not ok:raise AssertionError(message)

def blob(data):
    return hashlib.sha1("blob %d\0%s" % (len(data),data)).hexdigest()

def main():
    frozen=open(FROZEN,"rb").read()
    executed=open(EXECUTED,"rb").read()
    require(frozen==executed and blob(frozen)==EXPECTED_BLOB and
            hashlib.sha256(frozen).hexdigest()==EXPECTED_SHA256,
            "tested Native w source differs from frozen SHA-pinned QA candidate")
    original=native.CODE
    require(original!=frozen,
            "Native w experiment was improperly promoted to production source")
    previous=original.split("\n")
    current=frozen.split("\n")
    require(len(previous)==len(current)==2016 and
            previous[1334][native.P[0]]==current[1334][native.P[0]]=="p" and
            previous[1334][native.G[0]]==current[1334][native.G[0]]=="g" and
            previous[1331][958]==current[1331][958]=="j",
            "Native p/g/j scratch or real fault-injection cell drifted")
    native.CODE=frozen
    native.main()
    print("NATIVE_W_SAME_PROGRAM_FAULT_RESET_PASS",
          "two_live_native_programs",2,
          "same_program_explicit_reset_cases",3,
          "fault_injected_between_p_and_g",True)
    print("STAGE1_SEMANTIC_STATE_OWNERSHIP_FINAL_ACCEPTANCE=OPEN")

if __name__=="__main__":
    main()
