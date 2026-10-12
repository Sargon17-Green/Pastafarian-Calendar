#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 finite exhaustive signed-day square for the BF98 four-cell candidate.

All arithmetic takes place in actual PyFunge-98 production, test-only candidate,
and three independent Befunge-98 reference executions per valid input.
Python dispatches programs and validates evidence; it is NOT a date oracle.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_diverse_geometry as native
import stage1_native_lower_feedback_semantic_candidate as builder

OUT = "/four-cell-small-grid"
ORIGINAL = "560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE = "d965ce4bdfa282f2d3b82690808def5a2dde10a8"
VALUES = (-3, -2, -1, 0, 1, 2, 3)
INVALID = (
    (1,0,0,0), (0,0,1,0),
    (2,1,0,1), (0,1,2,1),
    (0,-1,0,1), (0,1,0,-1),
    (-1,1,0,1), (0,1,-1,1),
)

def need(ok, message):
    if not ok:
        raise AssertionError(message)

def encode(value):
    return (1 if value < 0 else 0, abs(value))

def roster():
    result = []
    for left in VALUES:
        for right in VALUES:
            s1,m1 = encode(left)
            s2,m2 = encode(right)
            result.append(("grid_%+d_%+d" % (left,right), (s1,m1,s2,m2), True))
    for i,fields in enumerate(INVALID):
        result.append(("invalid_%02d" % i,fields,False))
    return result

def main():
    need(os.path.isdir(OUT), "isolated Native small-grid output mount missing")
    source = open(native.SOURCE, "rb").read()
    need(builder.git_blob(source) == ORIGINAL, "Native BF98 production source changed")
    candidate = builder.candidate_bytes(source)
    need(builder.git_blob(candidate) == CANDIDATE,
         "Native BF98 four-cell patch identity changed")
    path = os.path.join(OUT,"small_grid_candidate.b98")
    with open(path,"wb") as f:
        f.write(candidate)
    cases = roster()
    need(len(cases)==57 and len(set(row[0] for row in cases))==57,
         "small-grid Native 49+8 roster changed")
    rows=[]
    for index,(label,fields,valid) in enumerate(cases):
        raw = " ".join(map(str,fields)) + "\n"
        original = native.native(native.SOURCE,raw)
        tested = native.native(path,raw)
        reference = native.expected_for(*fields) if valid else ["-1"]*7
        need(original == reference and tested == reference and len(reference)==7,
             "Native production/four-cell/reference disagreement at %s: %r / %r / %r" %
             (label, original, tested, reference))
        rows.append({
            "index":index,"case":label,"fields":list(fields),"valid":valid,
            "raw_input_sha256":hashlib.sha256(raw.encode("ascii")).hexdigest(),
            "production_native_output":original,
            "candidate_native_output":tested,
            "independent_befunge_reference_output":reference,
            "reference_native_processes":3 if valid else 0,
            "both_native_programs_completed":True,
        })
        print("NATIVE_FOUR_CELL_SIGNED_SMALL_GRID_PASS",index+1,"/",len(cases),
              label,"refs",3 if valid else 0)
        sys.stdout.flush()
    report = {
       "schema":"befunge-stage1-four-cell-native-exhaustive-small-grid-v1",
       "status":"FINITE_QA_ONLY_NOT_STAGE1_ACCEPTANCE",
       "production_blob":ORIGINAL,"candidate_blob":CANDIDATE,
       "signed_day_domain":list(VALUES),
       "valid_pairs":49,"invalid_lexical_domain_cases":8,
       "native_production_processes":57,"native_candidate_processes":57,
       "independent_native_reference_processes":147,
       "total_fresh_native_processes":261,
       "all_seven_field_results_agree":True,
       "test_only_variant":True,"production_source_modified":False,
       "stage1_complete":False,"stage2_started":False,
       "cases":rows,
    }
    with open(os.path.join(OUT,"small_grid_native_parity.json"),"wb") as f:
        f.write((json.dumps(report,sort_keys=True,indent=2)+"\n").encode("ascii"))
    print("NATIVE_FOUR_CELL_EXHAUSTIVE_SIGNED_SMALL_GRID_49_VALID_8_INVALID_261_PROCESS_PASS")
    print("LAST_COMPLETED_STAGE=0; STAGE2_STARTED=NO")

if __name__ == "__main__":
    main()
