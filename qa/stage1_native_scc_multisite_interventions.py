#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1: physical Native p -> g interventions at TWO more SCC memory cells.

No Python calendar computation or new Befunge source. Reuse the exact
real PyFunge stepping, first-p/first-g observation and independent Native
Befunge reference checks from the previously 41/41-green one-cell probe.
The site parameters are selected from actual SHA-verified Native TSV
artifact 11664135758; only one runtime memory cell is altered before g.
Scope is 2 sites x 9 inputs x sham/mutant = 36 Native Program executions,
with genuinely measured output effects (never assumed).
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_scc_g_intervention as old
import stage1_native_diverse_geometry as suite

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT = "/scc-multisite/native_scc_multisite_interventions.json"
CASES = (
    ("foundation_cross", True, 23207, 23287, 0, 23389, 23669, -2),
    ("forward_short", True, 11523, 11603, 2, 11705, 11985, 3),
    ("reverse_short", True, 11523, 11603, 1, 11705, 11985, 3),
    ("mixed_small", True, 11447, 11527, 1, 11629, 11909, 0),
    ("positive_negative", True, 24963, 25043, -1, 25145, 25425, 8),
    ("negative_positive", True, 24887, 24967, 9, 25069, 25349, 8),
    ("large_values", True, 75363, 75443, -7, 75545, 75825, 1),
    ("recent_anchor_next", True, 21603, 21683, 0, 21785, 22065, 9),
    ("invalid_big_sign", False, 13191, 13271, 0, 13373, 13653, 0),
)
SITES = (
    {"name":"cell41", "cell":(41,1701), "writer":(405,860),
     "reader":(749,290), "distance":80, "index":2},
    {"name":"cell43", "cell":(43,1702), "writer":(962,480),
     "reader":(958,1050), "distance":280, "index":5},
)

def require(cond,why):
    if not cond: raise AssertionError(why)

def main():
    require(os.path.isdir("/scc-multisite"),
            "missing Native two-site evidence volume")
    source=open(old.SRC,"rb").read()
    require(old.blob(source)==PIN,"production Befunge Git blob changed")
    casebook=dict((name,(fields,valid)) for name,fields,valid in suite.CASES)
    baseline_native={}
    records=[]
    for site in SITES:
        old.CELL=site["cell"]
        old.WRITER=site["writer"]
        old.READER=site["reader"]
        for item in CASES:
            label,valid=item[0],item[1]
            index=site["index"]
            wt,rt,value=item[index:index+3]
            require(rt-wt==site["distance"],
                    "Native trace-pinned actual p/g timing drift")
            require(label in casebook and casebook[label][1]==valid,
                    "Native input no longer from pinned arithmetic casebook")
            fields,ignored=casebook[label]
            raw=" ".join(map(str,fields))+"\n"
            if label not in baseline_native:
                baseline_native[label]=(suite.expected_for(*fields)
                                        if valid else ["-1"]*7)
            expected=baseline_native[label]
            require(len(expected)==7,
                    "independent real Befunge reference is incomplete")
            sham=old.program_case(source,raw,wt,rt,value,False)
            mutant=old.program_case(source,raw,wt,rt,value,True)
            require(sham["status"]=="normal" and
                    sham["remaining_ips"]==0 and sham["output"]==expected and
                    sham["actual_g_return"]==value,
                    "sham no longer equals independent Native Befunge reference "+label)
            require(mutant["actual_g_return"]==value+1,
                    "real Native g ignored the single-site memory intervention")
            require(sham["steps"]>=rt and mutant["steps"]>=rt,
                    "physical g event was not executed before reported end")
            changed=old.signature(sham)!=old.signature(mutant)
            records.append({
                "site":site["name"],"case":label,"valid":bool(valid),
                "input_fields":list(fields),
                "physical_cell":list(site["cell"]),
                "physical_writer":list(site["writer"]),
                "physical_reader":list(site["reader"]),
                "native_writer_tick":wt,"native_reader_tick":rt,
                "cell_before":value,"cell_after":value+1,
                "independent_native_oracle":expected,
                "control":sham,"intervention":mutant,
                "final_output_or_termination_changed":bool(changed),
                "actual_output_changed":sham["output"]!=mutant["output"],
            })
            print("NATIVE_SCC_SECOND_SITE_G_INTERVENTION_PASS",
                  site["name"],label,"write",wt,"read",rt,
                  "value",value,"to",value+1,
                  "output_or_termination_changed",bool(changed))
            sys.stdout.flush()
    require(len(records)==18 and
            sum(x["valid"] for x in records)==16,
            "2x9 Native SCC real physical p/g interventions missing")
    per_site=dict((site["name"], {
        "cases":sum(x["site"]==site["name"] for x in records),
        "g_returns_changed":sum(x["site"]==site["name"] and
                                 x["intervention"]["actual_g_return"]!=
                                 x["control"]["actual_g_return"] for x in records),
        "output_or_termination_changed":sum(
            x["site"]==site["name"] and
            x["final_output_or_termination_changed"] for x in records),
        "actual_output_changed":sum(x["site"]==site["name"] and
                                    x["actual_output_changed"] for x in records),
    }) for site in SITES)
    report={
      "schema":"befunge-stage1-native-scc-two-site-intervention-v1",
      "source_git_blob":PIN,
      "source_geometry_artifact_id":11664135758,
      "status":"OBSERVED_NATIVE_DEPENDENCE_FINITE_CORPUS_STAGE1_OPEN",
      "new_distinct_cells":2,
      "native_live_program_executions":36,
      "native_control_mutant_pairs":18,
      "unique_input_cases":9,
      "valid_case_site_pairs":16,
      "invalid_case_site_pairs":2,
      "independent_native_oracle_invocations":24,
      "site_stats":per_site,
      "records":records,
      "functional_acceptance":False,
      "geometric_acceptance":False,
    }
    with open(OUT,"wb") as stream:
        stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_SCC_TWO_MORE_CELLS_18_PHYSICAL_G_PAIRS_PASS",
          json.dumps(per_site,sort_keys=True))
    print("STAGE1_FUNCTIONAL_QA_PASS=NO GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    main()
