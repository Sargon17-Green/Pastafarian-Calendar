#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Verify ten truly native differential Funge trace files and record coverage.

This is *trace verification*, never Python calendar computation. The native
Befunge outputs were checked against independent native references by the
Python-2 runner. Here Python 3 checks pinned trace digests, temporal p/g,
executed source-map opcodes and graph coverage through the existing auditor.
"""
import gzip
import hashlib
import json
import os
import sys
import stage1_native_route_graph as geometry

LABELS=("zero_equal","foundation_cross","forward_short","reverse_short",
        "mixed_small","positive_negative","negative_positive",
        "large_values","invalid_zero_sign","invalid_big_sign")
WATCHED="_|[]rwjk{}ut()"

def require(ok,why):
    if not ok:
        raise AssertionError(why)

def read_arithmetic_edges(path):
    """Only native steps from original arithmetic handoff, not scanner."""
    entered=False
    previous=None
    with open(path,"r",encoding="ascii") as stream:
        for line in stream:
            if not line.startswith("STEP\\t"):
                continue
            fields=line.rstrip("\\n").split("\\t")
            require(len(fields)==9,"invalid native IP graph STEP")
            now=(int(fields[3]),int(fields[4]))
            if not entered:
                if now!=(5,0):
                    continue
                entered=True
            if previous is not None:
                yield previous,now
            previous=now
    require(entered,"missing arithmetic handoff in native graph")

def main(folder):
    with open(os.path.join(folder,"diverse_manifest.json"),"r",encoding="utf-8") as src:
        manifest=json.load(src)
    require(manifest.get("schema")=="befunge-stage1-diverse-native-v1",
            "unexpected native trace manifest")
    items=manifest.get("cases",[])
    require(tuple(x.get("case") for x in items)==LABELS,
            "missing or reordered native geometry scenarios")
    require(sum(bool(x["valid"]) for x in items)==8,"native valid family missing")
    require(sum(not bool(x["valid"]) for x in items)==2,"native invalid family missing")
    source=geometry.load_source("src/interleaved_work_counts.b98")
    reports=[]
    cross_input_out={}
    cross_input_in={}
    opcode_totals={key:0 for key in WATCHED}
    fingerprints=set()
    for item in items:
        label=item["case"]
        path=os.path.join(folder,item["trace_file"])
        require(os.path.dirname(os.path.normpath(item["trace_file"]))=="",
                "unexpected input filename path")
        with open(path,"rb") as stream:
            sha=hashlib.sha256(stream.read()).hexdigest()
        require(sha==item["trace_sha256"],"native trace digest mismatch "+label)
        for prev,nxt in read_arithmetic_edges(path):
            cross_input_out.setdefault(prev,set()).add(nxt)
            cross_input_in.setdefault(nxt,set()).add(prev)
        actual=geometry.analyze(source,path)
        stats=actual["statistics"]
        require(stats["native_ip_ids"]==1,"unexpected multiple native IPs")
        require(stats["arithmetic_steps"]>1000,
                "insufficient executed main arithmetic path for "+label)
        op=actual["arithmetic_executed_opcodes"]
        require(op.get("x",0)>30 and op.get("p",0)>1 and op.get("g",0)>1,
                "dynamic source writes/reads were not exercised in "+label)
        require(stats["executed_content_changing_gate_writes"]>=2,
                "changed runtime code did not influence native execution in "+label)
        require(len(item["output"])==7,"native output shape for "+label)
        for key in WATCHED:
            opcode_totals[key]+=op.get(key,0)
        fingerprints.add((stats["arithmetic_steps"],
                          stats["arithmetic_unique_coordinates"]))
        archive=os.path.join(folder,label+".graph.json.gz")
        with gzip.open(archive,"wb") as stream:
            stream.write(json.dumps(actual,sort_keys=True,
                                    separators=(",",":")).encode("utf-8"))
        reports.append({
          "case":label,"valid":item["valid"],"native_trace_sha256":sha,
          "arithmetic_steps":stats["arithmetic_steps"],
          "unique_executed_cells":stats["arithmetic_unique_coordinates"],
          "executed_write_then_reexecuted_gate":stats["executed_gate_writes"],
          "changed_executable_gate_reexecutions":
              stats["executed_content_changing_gate_writes"],
          "executed_p":op.get("p",0),"executed_g":op.get("g",0),
          "executed_x":op.get("x",0),
          "graph_merge_and_fork_nodes":stats["graph_merge_and_fork_nodes"],
          "unproven_advanced_opcode_execution":{c:op.get(c,0) for c in WATCHED}})
        print("NATIVE_DIVERSE_SOURCE_GRAPH_PASS",label,
              "steps",stats["arithmetic_steps"],
              "changed_reexecuted",stats["executed_content_changing_gate_writes"])
    forks={p for p,targets in cross_input_out.items() if len(targets)>1}
    joins={p for p,sources in cross_input_in.items() if len(sources)>1}
    merge_forks=forks & joins
    # This is an actual native across-input route property. Individual
    # runs have no merge-and-fork nodes, but two different signed-day
    # classes may follow different branches of the same arithmetic cell.
    require(len(forks)>=1 and len(joins)>=1,
            "no measured cross-input arithmetic fork/join differentiation")
    require(len(fingerprints)>=3,
            "diverse native cases generated insufficient route differentiation")
    with open(os.path.join(folder,"diverse_geometry_evidence.json"),"w",
              encoding="utf-8") as out:
        json.dump({"schema":"befunge-stage1-diverse-geometry-v1",
                   "source":"native PyFunge executed IP/p/g traces",
                   "status":"OBSERVED_GEOMETRY_ONLY_NOT_FULL_SPAGHETTI_PASS",
                   "route_fingerprints":len(fingerprints),
                   "cross_input_native_union_arithmetic_forks":len(forks),
                   "cross_input_native_union_arithmetic_joins":len(joins),
                   "cross_input_native_union_merge_and_fork_nodes":len(merge_forks),
                   "cross_input_native_union_fork_coordinates":
                       [list(x) for x in sorted(forks)],
                   "cross_input_native_union_join_coordinates":
                       [list(x) for x in sorted(joins)],
                   "coverage":reports,
                   "watched_advanced_opcode_execution_totals":opcode_totals,
                   "open":"Full structural geometry acceptance, anti-dead-code, cross-input gate"},
                  out,sort_keys=True,indent=2)
    print("NATIVE_STAGE1_DIVERSE_GEOMETRY_EVIDENCE_PASS",
          len(items),"native cases",len(fingerprints),"distinct route fingerprints",
          "cross-input forks",len(forks),
          "joins",len(joins),"merge-and-fork",len(merge_forks))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO pending full architectural proof")
if __name__=="__main__":
    require(len(sys.argv)==2,"usage: ... DIVERSE_TRACE_DIR")
    main(sys.argv[1])
