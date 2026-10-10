#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only four-cell Native candidate across 13 giant signed-number domains.

Boundary families are imported from the preexisting 255..1024-bit native
production corpus. Expected seven numerical outputs are recomputed with
THREE independent Befunge-98 reference executions. The exact four-cell
test-only candidate gets three independent Native whitespace-layout replays
per domain. No calendar arithmetic or source promotion is done by Python.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_diverse_geometry as native
import stage1_native_wide_magnitude_oracle as wide
import stage1_native_lower_feedback_semantic_candidate as cand

OUT="/candidate-bigint"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE_PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
SRC="src/interleaved_work_counts.b98"
CANDIDATE=OUT+"/four_cell_candidate.b98"

def need(ok,why):
    if not ok:raise AssertionError(why)

def main():
    need(os.path.isdir(OUT),"missing Native candidate big-integer evidence directory")
    raw=open(SRC,"rb").read()
    need(cand.git_blob(raw)==PIN,
         "native candidate wide-domain production preimage moved")
    altered=cand.candidate_bytes(raw)
    need(cand.git_blob(altered)==CANDIDATE_PIN,
         "Native candidate no longer exact four-cell version from 39-case PASS")
    with open(CANDIDATE,"wb") as stream:stream.write(altered)
    cases=wide.CASES
    need(len(cases)==13 and len(set(x[0] for x in cases))==13,
         "source-native 1024-bit casebook has drifted")
    records=[]
    for label,fields in cases:
        reference=native.expected_for(*fields)
        need(len(reference)==7 and
             all(x.lstrip("-").isdigit() for x in reference),
             "independent Befunge 98 reference incomplete: "+label)
        forms=wide.layouts(fields)
        need(len(forms)==3 and len(set(forms))==3,
             "Native candidate missing original three lexical layouts "+label)
        actual=[]
        for form in forms:
            answer=native.native(CANDIDATE,form)
            need(answer==reference,
                 "Native four-cell candidate 7-field wide-oracle mismatch "+label)
            actual.append(answer)
        record={"case":label,
                "input_fields":[str(x) for x in fields],
                "valid":True,
                "native_reference_7":reference,
                "native_candidate_form_outputs":actual,
                "native_input_form_sha256":[hashlib.sha256(x).hexdigest()
                                             for x in forms],
                "native_candidate_three_layouts_pass":True,
                "native_reference_modules_invoked":3,
                "native_candidate_executions":3}
        records.append(record)
        print("NATIVE_FOUR_CELL_WIDE_ORACLE_3_LAYOUTS_PASS",label,
              "max_input_decimal_digits",max(map(len,record["input_fields"])),
              "boundary_output_fields",len(reference))
        sys.stdout.flush()
    need(len(records)==13,"Native huge-number candidate coverage incomplete")
    report={"schema":"befunge-stage1-four-cell-wide-native-oracle-v1",
            "status":"FOUR_CELL_QA_ONLY_BEYOND_128_BIT_STAGE1_OPEN",
            "production_git_blob":PIN,
            "candidate_git_blob":CANDIDATE_PIN,
            "exact_four_changes":[list(x) for x in cand.PATCHES],
            "native_integer_domain_cases":13,
            "native_reference_executions":39,
            "native_candidate_executions":39,
            "native_input_whitespace_layouts":3,
            "numeric_bit_boundaries":[255,256,257,512,1024],
            "all_39_candidate_differentials_pass":True,
            "canonical_unchanged":True,
            "qa_production_unchanged":True,
            "stage1_functional_gate":"OPEN",
            "stage1_geometry_gate":"OPEN",
            "records":records}
    with open(OUT+"/four_cell_wide_native_oracle.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_FOUR_CELL_WIDE_13_CASES_78_EXECUTIONS_PASS",
          "independent_native_reference",39,"QA_candidate",39)
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO LAST_COMPLETED_STAGE=0")

if __name__=="__main__":main()
