#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent Native Funge98 graph/source-state audit for test-only w candidate.

Consumes real PyFunge STEP/READ/WRITE evidence and an already-pinned 2D
Befunge source. Does not implement Pastafarian arithmetic or accept Stage 1.
"""
import hashlib
import json
import os
import sys
import stage1_native_route_graph as native
import stage1_native_diverse_geometry_audit as corpus

SOURCE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
OUT="w_data_graph_audit.json"
W=(951,1332)
EXPECTED_SHA256="9b1fb027286ca8bf881d9edcd97385843760fc0be48eb83d4c08d1a84c3d739e"
EXPECTED_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
NEXT={"right":(952,1332),"straight":(951,1331)}

def check(ok,msg):
    if not ok:raise AssertionError(msg)

def main(folder):
    with open(SOURCE,"rb") as src:
        source_bytes=src.read()
    check(hashlib.sha256(source_bytes).hexdigest()==EXPECTED_SHA256 and
          hashlib.sha1(b"blob %d\0"%len(source_bytes)+source_bytes).hexdigest()==EXPECTED_BLOB,
          "frozen w Native source digest mismatch")
    path=os.path.join(folder,"w_data_candidate_proof.json")
    with open(path,"r",encoding="utf-8") as src:proof=json.load(src)
    check(proof["schema"]=="befunge-stage1-native-w-data-selected-arithmetic-v1" and
          proof["status"]=="QA_CANDIDATE_ONLY_NOT_PROMOTED" and
          proof["exact_source_sha256"]==EXPECTED_SHA256 and
          proof["frozen_candidate_git_blob"]==EXPECTED_BLOB and
          proof["changed_source_cells"]==28,
          "w Native proof artifact provenance or scope changed")
    records=proof["cases"]
    check(len(records)==17 and
          tuple(x["case"] for x in records)==corpus.LABELS and
          sum(bool(r["valid"]) for r in records)==14,
          "native selected corpus incomplete/reordered")
    extended=proof["extended_signed_domain_cases"]
    check(len(extended)==22 and sum(bool(x["valid"]) for x in extended)==18,
          "w Native large domain matrix absent or incomplete")
    source=native.load_source(SOURCE)
    lower=straight=right=0
    audit=[]
    for row in records:
        label=row["case"]
        file_name=row["trace_file"]
        check(file_name==label+".tsv","w trace filename/identity invalid")
        trace_file=os.path.join(folder,file_name)
        with open(trace_file,"rb") as stream:
            trace_sha=hashlib.sha256(stream.read()).hexdigest()
        check(trace_sha==row["trace_sha256"],"w Native trace sha mismatch "+label)
        graph=native.analyze(source,trace_file)
        ops=graph["arithmetic_executed_opcodes"]
        st=graph["statistics"]
        check(st["native_ip_ids"]==1 and
              st["executed_content_changing_gate_writes"]>=2 and
              st["reads"]==st["reads_completed"] and
              st["writes"]==st["writes_completed"],
              "actual Native IP or mutable Funge source lifecycle invalid "+label)
        edges=graph["observed_directed_edges"]
        succ={tuple(x["to"]) for x in edges if tuple(x["from"])==W}
        pred={tuple(x["from"]) for x in edges if tuple(x["to"])==W}
        executed=[c for c in graph["executed_source_map"] if
                  (c["x"],c["y"])==W]
        if row["arm"]=="upper":
            expected=NEXT.get(row["w_mode"])
            check(expected is not None and succ=={expected} and
                  pred=={(951,1333)} and
                  ops.get("w",0)==1 and len(executed)==1 and
                  executed[0]["visits"]==1 and
                  executed[0]["initial_byte"]==ord("w") and
                  executed[0]["final_byte"]==ord("w"),
                  "Native input-selected w comparator was not actually executed "+label)
            if row["w_mode"]=="right":right+=1
            else:straight+=1
        else:
            lower+=1
            check(row["arm"]=="lower" and row["w_mode"] is None and
                  ops.get("w",0)==0 and not succ and not pred and not executed,
                  "Native skipped lower path wrongly reached w arithmetic "+label)
        audit.append({"case":label,"native_real_w_executions":ops.get("w",0),
                      "arm":row["arm"],"mode":row["w_mode"],
                      "native_memory_write_events":st["writes"],
                      "native_memory_read_events":st["reads"],
                      "trace_sha256":trace_sha})
        print("NATIVE_W_INDEPENDENT_GRAPH_PASS",label,row["arm"],row["w_mode"],
              "w",ops.get("w",0))
    check((right,straight,lower)==(10,1,6),
          "actual w computed branch counts drifted")
    output={"schema":"befunge-stage1-independent-native-w-graph-v1",
            "scope":"QA_TEST_ONLY_NOT_STAGE1_ACCEPTANCE",
            "source_git_blob":EXPECTED_BLOB,"source_sha256":EXPECTED_SHA256,
            "right":right,"straight":straight,"lower":lower,
            "cases":audit}
    with open(os.path.join(folder,OUT),"w",encoding="utf-8") as sink:
        json.dump(output,sink,sort_keys=True,indent=2)
        sink.write("\n")
    print("NATIVE_W_INDEPENDENT_SOURCE_STATE_GRAPH_PASS",len(records),
          "right",right,"straight",straight,"lower",lower)
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; candidate evidence only")

if __name__=="__main__":
    check(len(sys.argv)==2,"usage: native_w_graph_audit TRACE_DIR")
    main(sys.argv[1])
