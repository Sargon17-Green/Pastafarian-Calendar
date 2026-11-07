#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only Native differential for the promoted reflective QA candidate.

No calendar arithmetic is implemented in Python. Expected valid outputs are
computed by three independent Befunge-98 reference programs. The previous
Native production source must independently match those same outputs.
Extra traces are retained for selected input-domain boundaries.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_diverse_geometry as native

BASE = "qa/interleaved_work_counts_pre_reflective_production.b98"
CANDIDATE = "qa/interleaved_work_counts_reflective_crossing_candidate.b98"
OUT = "/reflective"
BASE_BLOB = "44c5c33f4fe88ad82b8172235f18ad5d5175e517"
CANDIDATE_BLOB = "8f2cf8afef61818244747582fe7c20a74ee18943"
H = 2**127
L = 10**40 + 987654321
CASES = [
    ("zero_two",               (0,0,0,2), True),
    ("two_zero",               (0,2,0,0), True),
    ("equal_high",             (0,H,0,H), True),
    ("high_forward_neighbor",  (0,H,0,H+1), True),
    ("high_reverse_neighbor",  (0,H+1,0,H), True),
    ("negative_equal_high",    (1,H,1,H), True),
    ("negative_high_forward",  (1,H+1,1,H), True),
    ("negative_high_reverse",  (1,H,1,H+1), True),
    ("cross_high_forward",     (1,H,0,H), True),
    ("cross_high_reverse",     (0,H,1,H), True),
    ("foundation_to_origin",   (1,15055672,0,0), True),
    ("origin_to_foundation",   (0,0,1,15055672), True),
    ("recent_to_foundation",   (0,2461319,1,15055671), True),
    ("foundation_to_recent",   (1,15055671,0,2461319), True),
    ("decimal_cross_forward",  (0,L,1,10**41+123456789), True),
    ("decimal_cross_reverse",  (1,10**41+123456789,0,L), True),
    ("recent_adjacent",        (0,2461320,0,2461321), True),
    ("recent_reverse",         (0,2461321,0,2461320), True),
    ("invalid_source_zero",    (1,0,0,1), False),
    ("invalid_target_zero",    (0,1,1,0), False),
    ("invalid_source_sign",    (3,10,0,10), False),
    ("invalid_target_sign",    (0,10,3,10), False),
]
TRACE_LABELS = {"high_forward_neighbor","cross_high_reverse",
                "decimal_cross_forward"}

def require(ok,why):
    if not ok:
        raise AssertionError(why)

def git_blob(path):
    with open(path,"rb") as stream:
        data=stream.read()
    return hashlib.sha1("blob %d\0%s" % (len(data),data)).hexdigest()

def main():
    require(os.path.isdir(OUT),"expected mounted Native trace output folder")
    require(git_blob(BASE)==BASE_BLOB,"original production source blob drift")
    require(git_blob(CANDIDATE)==CANDIDATE_BLOB,
            "reflective candidate source blob drift")
    require(len(CASES)==22 and len(set(z[0] for z in CASES))==len(CASES),
            "extended signed-domain corpus mutated or duplicated")
    records=[]
    for label,fields,valid in CASES:
        raw=" ".join(map(str,fields))+"\n"
        reference=native.expected_for(*fields) if valid else ["-1"]*7
        baseline=native.native(BASE,raw)
        trace_path=(os.path.join(OUT,"extended_"+label+".tsv")
                    if label in TRACE_LABELS else None)
        candidate=native.native(CANDIDATE,raw,trace=trace_path)
        require(len(baseline)==len(candidate)==len(reference)==7,
                "seven-value Native output arity failed "+label)
        require(baseline==reference,
                "existing production fails independent Befunge oracle "+label)
        require(candidate==reference,
                "reflective candidate differs from independent Befunge oracle "+label)
        entry={"case":label,"inputs":list(fields),"valid":valid,
               "reference_fields":len(reference),"equal_old_native":True,
               "equal_candidate_native":True}
        if trace_path:
            with open(trace_path,"rb") as stream:
                content=stream.read()
            require(len(content)>50000,
                    "extended boundary Native trace not actually captured "+label)
            entry["trace_sha256"]=hashlib.sha256(content).hexdigest()
            entry["trace_file"]=os.path.basename(trace_path)
        records.append(entry)
        print("NATIVE_REFLECTIVE_WIDE_DOMAIN_ORACLE_PASS",label,
              "traced",bool(trace_path))
        sys.stdout.flush()
    report={"schema":"befunge-stage1-reflective-wide-domain-native-v1",
            "status":"QA_PRODUCTION_ONLY_NOT_STAGE1_ACCEPTANCE",
            "baseline_blob":BASE_BLOB,"candidate_blob":CANDIDATE_BLOB,
            "total":len(records),"valid":sum(bool(z[2]) for z in CASES),
            "invalid":sum(not z[2] for z in CASES),
            "extra_traces":len(TRACE_LABELS),"cases":records}
    with open(os.path.join(OUT,"reflective_wide_domain_proof.json"),"wb") as stream:
        stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_REFLECTIVE_WIDE_DOMAIN_PASS",len(records),
          "independent Befunge oracle plus old production parity")
    print("FULL_FUNCTIONAL_QA_PASS=NO GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    main()
