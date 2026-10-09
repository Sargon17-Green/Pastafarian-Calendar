#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent Native trace/graph verification for QA reflective candidate.

Verifies real read/write, historical executable bytes and actual per-run
directed edges; the normative calendar calculation remains only in Befunge.
Neither this audit nor a source-map-only check marks Stage 1 accepted.
"""
import hashlib
import json
import os
import sys
import stage1_native_route_graph as geometry
import stage1_native_diverse_geometry_audit as cases

SOURCE="qa/interleaved_work_counts_reflective_crossing_candidate.b98"
PIVOT=(958,1324)
PARENTS={(958,1325),(957,1324)}
CHILDREN={(957,1324),(958,1323)}

def require(flag,why):
    if not flag:
        raise AssertionError(why)

def main(folder):
    path=os.path.join(folder,"reflective_candidate_proof.json")
    with open(path,"r",encoding="utf-8") as stream:
        evidence=json.load(stream)
    require(evidence["schema"]=="befunge-stage1-native-reflective-crossing-candidate-v1",
            "unexpected reflective Native proof schema")
    require(evidence["candidate_blob"]=="8f2cf8afef61818244747582fe7c20a74ee18943",
            "independent source SHA provenance changed")
    require(evidence.get("qa_production_matches_candidate") is True,
            "Native evidence was not captured on the promoted QA source")
    with open(SOURCE,"rb") as reader: candidate_bytes=reader.read()
    with open("src/interleaved_work_counts.b98","rb") as reader:
        require(reader.read()==candidate_bytes,
                "production and independently audited candidate bytes differ")
    records=evidence["results"]
    require(tuple(x["case"] for x in records)==cases.LABELS and
            len(records)==17,"missing reordered or extra Native corpus cases")
    require(sum(x["branch"]=="up" for x in records)==11 and
            sum(x["branch"]=="down" for x in records)==6,
            "actual signed-day routes did not exercise both data-dependent arms")
    source=geometry.load_source(SOURCE)
    reports=[]
    for rec in records:
        label=rec["case"]
        filename=rec["trace_file"]
        require(filename==label+".tsv","untrusted trace path/label")
        path=os.path.join(folder,filename)
        with open(path,"rb") as stream:
            digest=hashlib.sha256(stream.read()).hexdigest()
        require(digest==rec["source_trace_sha256"],
                "native IP evidence digest mismatch "+label)
        trace=geometry.analyze(source,path)
        st=trace["statistics"]
        ops=trace["arithmetic_executed_opcodes"]
        node=next((n for n in trace["merge_fork_nodes"]
                   if (n["x"],n["y"])==PIVOT),None)
        edges=trace["observed_directed_edges"]
        parents={tuple(e["from"]) for e in edges if tuple(e["to"])==PIVOT}
        children={tuple(e["to"]) for e in edges if tuple(e["from"])==PIVOT}
        source_cell=next((z for z in trace["executed_source_map"]
                          if (z["x"],z["y"])==PIVOT),None)
        if rec["branch"]=="up":
            require(node is not None and node["incoming"]==2 and
                    node["outgoing"]==2 and st["graph_merge_and_fork_nodes"]>=1,
                    "no actual Native single-run merge-and-fork at "+label)
            require(parents==PARENTS and children==CHILDREN,
                    "native edges do not prove exact two-in/two-out at "+label)
            require(source_cell is not None and
                    source_cell["visits"]==2 and
                    source_cell["arrival_velocity_count"]==2 and
                    source_cell["initial_byte"]==ord("[") and
                    source_cell["final_byte"]==ord("["),
                    "Native instruction bytes/velocity history not genuine "+label)
            require(ops.get("r",0)==1 and ops.get("[",0)>=2,
                    "native reflection/rotation did not execute on computed path "+label)
        else:
            require(node is None and not parents and not children and
                    ops.get("r",0)==0,
                    "unselected candidate arm contaminated the lower arithmetic path")
        require(st["native_ip_ids"]==1 and
                st["executed_content_changing_gate_writes"]>=2 and
                st["reads"]==st["reads_completed"] and
                st["writes"]==st["writes_completed"],
                "Native read/write/executable-cell lifecycle failed "+label)
        reports.append({"case":label,"branch":rec["branch"],
                        "trace_sha256":digest,
                        "single_run_pivot_in_degree":len(parents),
                        "single_run_pivot_out_degree":len(children),
                        "r_executed":ops.get("r",0),
                        "reexecuted_changed_code":st["executed_content_changing_gate_writes"],
                        "native_memory_reads":st["reads"],
                        "native_memory_writes":st["writes"]})
        print("NATIVE_REFLECTIVE_INDEPENDENT_GRAPH_AUDIT_PASS",label,
              "branch",rec["branch"],"in",len(parents),"out",len(children),
              "actual_r",ops.get("r",0))
    report={"schema":"befunge-stage1-reflective-native-graph-audit-v1",
            "scope":"QA-only measured evidence, no final acceptance",
            "case_count":len(reports),"upper_dual_nodes":11,"lower_dual_nodes":0,
            "qa_candidate_promoted_only":True,"cases":reports}
    with open(os.path.join(folder,"reflective_graph_audit.json"),
              "w",encoding="utf-8") as out:
        json.dump(report,out,indent=2,sort_keys=True)
        out.write("\n")
    print("NATIVE_REFLECTIVE_INDEPENDENT_GRAPH_AUDIT_PASS",len(reports),
          "real Native byte-verified cases")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (QA production, not final acceptance)")
if __name__=="__main__":
    require(len(sys.argv)==2,"usage: independent_graph_audit NATIVE_TRACE_DIR")
    main(sys.argv[1])
