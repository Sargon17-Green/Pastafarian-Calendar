#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fail-closed *frontier measurement* from audited NATIVE Befunge trace graphs.

The code neither implements calendar arithmetic nor assigns acceptance.
The native origin, output-shape, step-by-step opcode/mutable-memory proof,
and trace digests are validated by stage1_native_diverse_geometry_audit.py
before this script runs. No source-map-only or decorative opcode is counted.
"""
import json
import os
import sys
import stage1_native_diverse_geometry_audit as corpus

REQUIRED_EXECUTED = tuple("><^v[]rwx_|jk")
STACK_STACK = ("{", "}", "u")
CONCURRENCY = ("t",)
FINGERPRINTS = ("(", ")")

def require(ok, why):
    if not ok:
        raise AssertionError(why)

def main(directory):
    infile=os.path.join(directory,"diverse_geometry_evidence.json")
    with open(infile,"r",encoding="utf-8") as stream:
        evidence=json.load(stream)
    require(evidence["schema"]=="befunge-stage1-diverse-geometry-v1",
            "geometry evidence must be derived from audited Native IP traces")
    require(evidence["status"]=="OBSERVED_GEOMETRY_ONLY_NOT_FULL_SPAGHETTI_PASS",
            "unexpected accept/reject semantics in measured geometry")
    coverage=evidence["coverage"]
    require(len(coverage)==17 and
            tuple(x["case"] for x in coverage)==corpus.LABELS and
            len({x["case"] for x in coverage})==17,
            "exact seventeen-case audited Native corpus is mandatory")
    require(sum(bool(x["valid"]) for x in coverage)==14 and
            sum(not bool(x["valid"]) for x in coverage)==3,
            "Native corpus lost required valid/invalid-case diversity")
    require(all(x["changed_executable_gate_reexecutions"]>=2 for x in coverage),
            "native self-modifying executable cell lifecycle not demonstrated")
    require(all(x["executed_p"]>1 and x["executed_g"]>1 and x["executed_x"]>30
                for x in coverage),
            "Native p/g/x arithmetic participation not demonstrated")
    totals=evidence["watched_advanced_opcode_execution_totals"]
    require(all(isinstance(v,int) and v>=0 for v in totals.values()),
            "negative or noninteger executed native opcode counts")
    forks=evidence["cross_input_native_union_arithmetic_forks"]
    joins=evidence["cross_input_native_union_arithmetic_joins"]
    dual=evidence["cross_input_native_union_merge_and_fork_nodes"]
    require(forks>=1 and joins>=1 and 0<=dual<=min(forks,joins),
            "invalid measured cross-input directed graph frontier")
    require(all(totals.get(ch,0)>0 for ch in ("[","]","|","j","k")),
            "promoted Native input-dependent turn/jump/k architecture missing")
    # The native graph's opcode watcher intentionally omits ordinary direction
    # and x, which are proven separately by stage1_native_route_graph.py.
    # Do not label those unknown counts as zero.
    watched=set(totals)
    missing=[op for op in REQUIRED_EXECUTED if op in watched and totals[op]==0]
    deferred={
      "stack_stack_missing_executed":[op for op in STACK_STACK
                                     if totals.get(op,0)==0],
      "native_concurrency_unproven":[op for op in CONCURRENCY
                                     if totals.get(op,0)==0],
      "fingerprints_unavailable_under_disable_fprint":list(FINGERPRINTS),
    }
    report={
      "schema":"befunge-stage1-native-executed-spaghetti-frontier-v1",
      "native_case_count":len(coverage),
      "proof_origin":"audited actual PyFunge STEP/WRITE/READ, not source bytes",
      "cross_input_arithmetic_forks":forks,
      "cross_input_arithmetic_joins":joins,
      "dual_merge_and_fork_nodes":dual,
      "route_fingerprints":evidence["route_fingerprints"],
      "advanced_executed_opcode_totals":totals,
      "missing_watched_advanced_control_operators":missing,
      "unproven_deferred_features":deferred,
      "required_control_opcodes_with_native_execution":{
          k:totals[k] for k in ("[","]","|","j","k")},
      "self_modifying_execution_minimum":min(
          x["changed_executable_gate_reexecutions"] for x in coverage),
      "current_geometry_gate":"OPEN",
      "reason":"Full interwoven recursive spaghetti, w/r/_ and stack-stack "
               "accounting are not proved by measured routes; "
               "merge-and-fork intersections require additional evidence",
      "current_functional_gate":"NOT_INFERRED_FROM_GEOMETRY",
      "last_completed_stage":"UNCHANGED_0",
    }
    outfile=os.path.join(directory,"native_spaghetti_frontier.json")
    with open(outfile,"w",encoding="utf-8") as stream:
        json.dump(report,stream,ensure_ascii=False,sort_keys=True,indent=2)
        stream.write("\n")
    print("NATIVE_SPAGHETTI_FRONTIER_MEASURED_PASS",
          "cases",len(coverage),"forks",forks,"joins",joins,
          "dual_nodes",dual,"missing_controls",",".join(missing) or "NONE")
    print("NATIVE_DEFERRED_SEMANTICS",json.dumps(deferred,sort_keys=True))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; evidence only, no automatic acceptance")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: ... NATIVE_TRACE_ARTIFACT_DIR")
    main(sys.argv[1])
