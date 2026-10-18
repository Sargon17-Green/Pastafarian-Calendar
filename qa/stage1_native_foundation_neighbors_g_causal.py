#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98 first p->g intervention for two untested Foundation neighbors.

Uses the ALREADY SOURCE-PINNED real SCC physical-cell runner; does not compute
calendar values in Python, alter Befunge source, or claim final Stage1 PASS.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_native_scc_g_intervention as native
import stage1_native_diverse_geometry as reference
ROOT="/foundation-neighbor-g"
WITNESSES=(("foundation_neighbor_forward",23083,23246,-1),
           ("foundation_neighbor_reverse",23083,23246,0))
def need(v,why):
    if not v:raise AssertionError(why)
def main():
    need(os.path.isdir(ROOT),"Native Foundation g-intervention mount unavailable")
    source=open(native.SRC,"rb").read()
    need(native.blob(source)==native.PIN
         and native.CELL==(37,1700)
         and native.WRITER==(1249,1050)
         and native.READER==(575,1164),"physical Native source pin or p/g target changed")
    cases=dict((n,(f,valid)) for n,f,valid in reference.CASES)
    records=[]
    for label,wt,rt,want in WITNESSES:
        fields,valid=cases[label]
        need(valid and rt-wt==163,"native Foundation neighbor must be valid")
        raw=" ".join(map(str,fields))+"\n"
        expected=reference.expected_for(*fields)
        original=native.program_case(source,raw,wt,rt,want,False)
        mutated=native.program_case(source,raw,wt,rt,want,True)
        need(original["status"]=="normal"
             and original["remaining_ips"]==0
             and original["output"]==expected
             and len(expected)==7
             and original["actual_g_return"]==want
             and mutated["actual_g_return"]==want+1
             and mutated["steps"]>=rt,
             "independent original BF98 oracle or real p->g mutation failed")
        altered=(native.signature(original)!=native.signature(mutated))
        final_numeric=(mutated["status"]=="normal"
                      and mutated["remaining_ips"]==0
                      and mutated["output"]!=expected
                      and len(mutated["output"])==7)
        records.append({"case":label,"fields":[str(v) for v in fields],
                        "reference_7":expected,"writer_tick":wt,
                        "reader_tick":rt,"written":want,
                        "mutated_read":want+1,"original":original,
                        "counterfactual":mutated,
                        "output_or_termination_changed":altered,
                        "normal_seven_field_numeric_change":bool(final_numeric)})
        print("NATIVE_FOUNDATION_NEIGHBOR_REAL_PG_CAUSAL_MEASURED",
              label,"physical_g",want,"to",want+1,
              "normal_numeric_change",bool(final_numeric),
              "counter_status",mutated["status"],
              "steps",mutated["steps"])
        sys.stdout.flush()
    report={"schema":"befunge-stage1-foundation-neighbors-native-g-causal-v1",
            "scope":"TWO_PREVIOUSLY_OBSERVATIONAL_NO_U_FOUNDATION_NEIGHBORS",
            "source_git_blob":native.PIN,
            "physical_cell":list(native.CELL),
            "writer_site":list(native.WRITER),
            "reader_site":list(native.READER),
            "native_executions":4,
            "independent_native_reference_cases":2,
            "native_counterfactual_pairs":2,
            "stage1_complete":False,
            "full_functional_qa_pass":False,
            "geometric_spaghetti_qa_pass":False,
            "production_modified":False,
            "records":records}
    with open(ROOT+"/native_foundation_neighbor_g_causal.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_BF98_FOUNDATION_NEIGHBOR_TWO_PG_CAUSAL_PAIRS_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
